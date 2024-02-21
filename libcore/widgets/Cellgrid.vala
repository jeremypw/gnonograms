/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.CellGrid : Gtk.DrawingArea {
    public signal void start_drawing (uint button, Gdk.ModifierType state, bool double_click);
    public signal void stop_drawing ();
    public signal void leave ();

    public View view { get; construct; }
    public Cell current_cell { get; set; }
    public Cell previous_cell { get; set; }
    public bool frozen { get; set; }
    public bool draw_only { get; set; default = false;}

    /* Could have more options for cell pattern*/
    private CellPatternType _cell_pattern_type;
    public CellPatternType cell_pattern_type {
        get {
            return _cell_pattern_type;
        }

        set {
            switch (value) {
                case CellPatternType.CELL: /* plain color fill */
                    filled_cell_pattern = new CellPattern.cell (fill_color);
                    empty_cell_pattern = new CellPattern.cell (empty_color);
                    unknown_cell_pattern = new CellPattern.cell (unknown_color);
                    _cell_pattern_type = value;

                    break;
                default:
                    /* Refresh colors of existing pattern */
                    if (_cell_pattern_type != CellPatternType.UNDEFINED) {
                        cell_pattern_type = _cell_pattern_type;
                    }

                    break;
            }
        }
    }

    private const double MAJOR_GRID_LINE_WIDTH = 3.0;
    private const double MINOR_GRID_LINE_WIDTH = 1.0;
    private Gdk.RGBA[, ] colors;

    private int rows = 0;
    private int cols = 0;
    private bool dirty = false; /* Whether a redraw is needed */
    private double cell_width; /* Width of cell including frame */
    private double cell_height; /* Height of cell including frame */

    private Gdk.RGBA grid_color;
    private Gdk.RGBA fill_color;
    private Gdk.RGBA empty_color;
    private Gdk.RGBA unknown_color;

    private CellPattern filled_cell_pattern;
    private CellPattern empty_cell_pattern;
    private CellPattern unknown_cell_pattern;
    private CellPattern highlight_pattern;

    private My2DCellArray? array {
        get {
            return view.model.display_data;
        }
    }

    public CellGrid (View view) {
        Object (
            view: view
        );
    }

    construct {
        _current_cell = NULL_CELL;
        colors = new Gdk.RGBA[2, 3];
        grid_color.parse (Gnonograms.GRID_COLOR);
        cell_pattern_type = CellPatternType.CELL;
        set_colors ();

        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);
        motion_controller.motion.connect (on_pointer_moved);
        motion_controller.leave.connect (on_leave_notify);

        var button_controller = new Gtk.GestureClick ();
        button_controller.set_button (0); // Listen to any button
        add_controller (button_controller);
        button_controller.pressed.connect ((n_press, x, y) => {
            start_drawing (
                button_controller.get_current_button (),
                button_controller.get_current_event_state (),
                n_press > 1);
        });
        button_controller.released.connect ((n_press, x, y) => {
            stop_drawing ();
        });

        set_draw_func (draw_func);

        notify["current-cell"].connect (() => {
            queue_draw ();
        });

        view.notify["cell-size"].connect (size_updated);
        view.controller.notify["dimensions"].connect (size_updated);
        view.controller.notify["game-state"].connect (() => {
            on_game_state_changed ();
        });

        view.model.changed.connect (() => {
            if (!dirty) {
                dirty = true;
                queue_draw ();
            }
        });

        size_updated ();
    }

    public void set_colors () {
        var setting = (int) GameState.SETTING;
        colors[setting, (int) CellState.UNKNOWN].parse (Gnonograms.UNKNOWN_COLOR);
        colors[setting, (int) CellState.EMPTY].parse (Gnonograms.SETTING_EMPTY_COLOR);
        colors[setting, (int) CellState.FILLED].parse (Gnonograms.SETTING_FILLED_COLOR);
        setting = (int) GameState.SOLVING;
        colors[setting, (int) CellState.UNKNOWN].parse (Gnonograms.UNKNOWN_COLOR);
        colors[setting, (int) CellState.EMPTY].parse (settings.get_string ("empty-color"));
        colors[setting, (int) CellState.FILLED].parse (settings.get_string ("filled-color"));
        on_game_state_changed ();
    }

    private void on_game_state_changed () {
        var gs = view.controller.game_state;
        unknown_color = colors[(int)gs, (int)CellState.UNKNOWN];
        fill_color = colors[(int)gs, (int)CellState.FILLED];
        empty_color = colors[(int)gs, (int)CellState.EMPTY];
        cell_pattern_type = CellPatternType.UNDEFINED; /* Causes refresh of existing pattern */
    }

    private void size_updated () {
        rows = (int)view.controller.dimensions.height;
        cols = (int)view.controller.dimensions.width;
        cell_width = view.cell_size;
        cell_height = view.cell_size;
        /* Cause refresh of existing pattern */
        highlight_pattern = new CellPattern.highlight (cell_width, cell_height);
        content_width = cols * view.cell_size + (int)MINOR_GRID_LINE_WIDTH;
        content_height = rows * view.cell_size + (int)MINOR_GRID_LINE_WIDTH;
    }

    private void draw_func (Gtk.DrawingArea drawing_area, Cairo.Context cr, int x, int y) {
        dirty = false;

        if (array != null) {
            /* Note, even tho' array holds CellStates, its iterator returns Cells */
            foreach (Cell c in array) {
                bool highlight = (c.row == current_cell.row && c.col == current_cell.col);
                draw_cell (cr, c, highlight);
            }
        }

        draw_grid (cr);
    }

    private double previous_pointer_x = 0.0;
    private double previous_pointer_y = 0.0;
    private void on_pointer_moved (double x, double y) {
        if (draw_only || x < 0 || y < 0) {
            return;
        }

        // Need to ignore spurious "movements" in Gtk4
        if (previous_pointer_x == x && previous_pointer_y == y) {
            return;
        } else {
            previous_pointer_x = x;
            previous_pointer_y = y;
        }
        /* Calculate which cell the pointer is over */
        uint r = ((uint)((y) / cell_height));
        uint c = ((uint)(x / cell_width));
        if (r >= rows || c >= cols) {
            return;
        }
        /* Construct cell beneath pointer */
        Cell cell = {r, c, array.get_data_from_rc (r, c)};
        if (!cell.equal (current_cell)) {
            previous_cell = current_cell.clone ();
            current_cell = cell.clone ();
        }

        return;
    }

    private void draw_grid (Cairo.Context cr) {
        Gdk.cairo_set_source_rgba (cr, grid_color);
        cr.set_antialias (Cairo.Antialias.NONE);
        cr.set_line_width (MINOR_GRID_LINE_WIDTH);

        // Draw minor grid lines
        double y1 = MINOR_GRID_LINE_WIDTH;
        double x1 = MINOR_GRID_LINE_WIDTH;
        double x2 = x1 + cols * view.cell_size;
        double y2 = y1 + rows * view.cell_size;
        while (y1 < y2) {
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
            y1 += view.cell_size;
        }

        y1 = MINOR_GRID_LINE_WIDTH;
        // x1 = MINOR_GRID_LINE_WIDTH;
        while (x1 < x2) {
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
            x1 += view.cell_size;
        }

        // Draw inner major grid lines
        cr.set_line_width (MAJOR_GRID_LINE_WIDTH);
        x1 = MINOR_GRID_LINE_WIDTH;
        while (y1 < y2) {
            y1 += 5.0 * view.cell_size;
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
        }

        y1 = MINOR_GRID_LINE_WIDTH;
        while (x1 < x2) {
            x1 += 5.0 * view.cell_size;
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
        }

        // Draw frame
        cr.set_line_width (MINOR_GRID_LINE_WIDTH);
        y1 = 0;
        x1 = 0;
        cr.move_to (x1, y1);
        cr.line_to (x2, y1);
        cr.stroke ();

        cr.line_to (x2, y2);
        cr.stroke ();

        cr.line_to (x1, y2);
        cr.stroke ();

        cr.line_to (x1, y1);
        cr.stroke ();
    }

    private void draw_cell (Cairo.Context cr, Cell cell, bool highlight = false, bool mark = false) {
        if (frozen) {
            return;
        }

        double x = cell.col * cell_width;
        double y = cell.row * cell_height;
        CellPattern cell_pattern;
        switch (cell.state) {
            case CellState.EMPTY:
                cell_pattern = empty_cell_pattern;
                break;

            case CellState.FILLED:
                cell_pattern = filled_cell_pattern;
                break;

            default :
                cell_pattern = unknown_cell_pattern;
                break;
        }

        cr.save ();
        cell_pattern.move_to (x, y); /* Not needed for plain fill, but may use a pattern later */
        cr.set_line_width (0.0);
        cr.rectangle (x, y, cell_width, cell_height);
        cr.set_source (cell_pattern.pattern);
        cr.fill ();
        cr.restore ();

        if (highlight && !draw_only) {
            cr.save ();
            /* Ensure highlight centred and slightly overlapping grid */
            highlight_pattern.move_to (x, y);
            cr.rectangle (x, y, cell_width, cell_width);
            cr.clip ();
            cr.set_source (highlight_pattern.pattern);
            cr.set_operator (Cairo.Operator.OVER);
            cr.paint ();
            cr.restore ();
        }
    }

    private void on_leave_notify () {
        previous_cell = NULL_CELL;
        current_cell = NULL_CELL;
        leave ();
        return;
    }

    public override void measure (
        Gtk.Orientation orientation,
        int for_size,
        out int minimum,
        out int natural,
        out int minimum_baseline,
        out int natural_baseline
    ) {
        if (orientation == HORIZONTAL) {
            minimum = (int)(cell_width * cols);
            natural = minimum;
            minimum_baseline = -1;
            natural_baseline = -1;
        } else {
            minimum = (int)(cell_height * rows);
            natural = minimum;
            minimum_baseline = -1;
            natural_baseline = -1;
        }
    }

    private class CellPattern {
        public Cairo.Pattern pattern;
        public double size { get; private set; }
        private double red;
        private double green;
        private double blue;
        private double x0 = 0;
        private double y0 = 0;
        private Cairo.Matrix matrix;

        public CellPattern.cell (Gdk.RGBA color) {
            red = color.red;
            green = color.green;
            blue = color.blue;
            matrix = Cairo.Matrix.identity ();

            var granite_settings = Granite.Settings.get_default ();
            set_pattern (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK);

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                set_pattern (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK);
            });
        }

        public CellPattern.highlight (double wd, double ht) {
            var r = (wd + ht) / 4.0;
            size = 2 * r;

            Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, (int)size, (int)size);
            Cairo.Context context = new Cairo.Context (surface);
            context.set_source_rgb (0.0, 0.0, 0.0);
            context.rectangle (0, 0, size, size);
            context.fill ();
            context.arc (r, r, r - 2.0, 0, 2 * Math.PI);
            context.set_source_rgba (1.0, 1.0, 1.0, 0.5);
            context.set_operator (Cairo.Operator.SOURCE);
            context.fill ();

            pattern = new Cairo.Pattern.for_surface (surface);
            pattern.set_extend (Cairo.Extend.NONE);
            matrix = Cairo.Matrix.identity ();
            pattern.set_matrix (matrix);
        }

        public void move_to (double x, double y) {
            var xx = x - x0;
            var yy = y - y0;
            matrix.translate (-xx, -yy);
            pattern.set_matrix (matrix);
            x0 = x;
            y0 = y;
        }

        private void set_pattern (bool is_dark) {
            pattern = new Cairo.Pattern.rgba (
                is_dark ? red / 2 : red,
                is_dark ? green / 2 : green,
                is_dark ? blue / 2 : blue,
                1.0
            );
        }
    }
}
