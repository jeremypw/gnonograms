/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public enum Gnonograms.CellState {
    UNKNOWN,
    EMPTY,
    FILLED,
    COMPLETED,
    INVALID
}

public struct Gnonograms.Cell {
    public uint row;
    public uint col;
    public CellState state;

    public bool same_coords (Cell c) {
        return (this.row == c.row && this.col == c.col);
    }

    public bool equal (Cell? b) {
        return (
            b != null &&
            this.row == b.row &&
            this.col == b.col &&
            this.state == b.state
        );

    }

    public bool same_place (Cell? b) {
        return (
            b != null &&
            this.row == b.row &&
            this.col == b.col
        );

    }

    public Cell inverse () {
        Cell c = {row, col, CellState.UNKNOWN };

        if (this.state == CellState.EMPTY) {
            c.state = CellState.FILLED;
        } else {
            c.state = CellState.EMPTY;
        }

        return c;
    }

    public Cell clone () {
        return { row, col, state };
    }

    public string to_string () {
        return "Row %u, Col %u, State %s".printf (row, col, state.to_string ());
    }
}

public class Gnonograms.CellGrid : Gtk.DrawingArea {
    public signal void leave ();

    public unowned View view { get; construct; }
    public Cell? current_cell { get; set; }
    public Cell? previous_cell { get; set; }
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

    public double cell_width { get; private set; } /* Width and Height of cell including frame */
    public double cell_height { get; private set; }/* Width and Height of cell including frame */
    private bool dirty = false; /* Whether a redraw is needed */

    private uint rows = 5;
    private uint cols = 5;
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
        var app = ((Gnonograms.App)(Application.get_default ()));
        hexpand = true;
        vexpand = true;
        current_cell = null;
        colors = new Gdk.RGBA[2, 3];
        grid_color.parse (Gnonograms.GRID_COLOR);
        cell_pattern_type = CellPatternType.CELL;
        set_colors ();

        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);
        motion_controller.motion.connect (on_pointer_moved);
        motion_controller.leave.connect (on_leave_notify);

        set_draw_func (draw_func);

        notify["current-cell"].connect (() => {
            queue_draw ();
        });

        app.game_state_changed.connect (on_game_state_changed);
        app.dimensions_changed.connect (on_dimensions_changed);

        view.model.changed.connect (() => {
            if (!dirty) {
                dirty = true;
                queue_draw ();
            }
        });

        settings.changed["filled-color"].connect (set_colors);
        settings.changed["empty-color"].connect (set_colors);
    }

    public void on_dimensions_changed (uint rows, uint cols) {
        this.rows = rows;
        this.cols = cols;
        queue_allocate ();
    }

    public void set_colors () {
        // Ensure settings have updated
        Idle.add (() => {
            var setting = (int) GameState.SETTING;
            colors[setting, (int) CellState.UNKNOWN].parse (Gnonograms.UNKNOWN_COLOR);
            colors[setting, (int) CellState.EMPTY].parse (Gnonograms.SETTING_EMPTY_COLOR);
            colors[setting, (int) CellState.FILLED].parse (Gnonograms.SETTING_FILLED_COLOR);
            setting = (int) GameState.SOLVING;
            colors[setting, (int) CellState.UNKNOWN].parse (Gnonograms.UNKNOWN_COLOR);
            colors[setting, (int) CellState.EMPTY].parse (settings.get_string ("empty-color"));
            colors[setting, (int) CellState.FILLED].parse (settings.get_string ("filled-color"));
            update_colors ();
            queue_draw ();
            return Source.REMOVE;
        });
    }

    private GameState gs;
    private void on_game_state_changed (GameState gs) {
        this.gs = gs;
        update_colors ();
    }
    
    private void update_colors () {
        unknown_color = colors[(int)gs, (int)CellState.UNKNOWN];
        fill_color = colors[(int)gs, (int)CellState.FILLED];
        empty_color = colors[(int)gs, (int)CellState.EMPTY];
        cell_pattern_type = CellPatternType.UNDEFINED; /* Causes refresh of existing pattern */
    }

    public override void size_allocate (int w, int h, int bl) {
        var r = (double) rows;
        var c = (double) cols;
        // Need to allow window to be shrunk and create bottom/end margins
        var dw = (double) w - c - 12;
        var dh = (double) h - r - 12;
        if (r == 0 || c == 0) {
            return;
        }
        var width_for_height = dh * c / r;
        var height_for_width = dw * r / c;
        //Calculate content dimensions, optimise fit in available space, keeping square cells
        double height, width;
        if (width_for_height > dw) {
            width = dw;
            height = height_for_width;
        } else if (height_for_width > dh) {
            height = dh;
            width = width_for_height;
        } else {
            height = dh;
            width = dw;
        }

        // Cell width and height should be the same but leave separate for now.
        cell_width = width / c;
        cell_height = height / r;

        content_width = (int) (width + 0.99);
        content_height = (int) (height + 0.99);

        /* Cause refresh of existing pattern */
        highlight_pattern = new CellPattern.highlight (cell_width, cell_height);
    }

    private void draw_func (
        Gtk.DrawingArea drawing_area, 
        Cairo.Context cr, 
        int x, 
        int y
    ) {
    
        dirty = false;
        if (array != null) {
            /* Note, even tho' array holds CellStates, its iterator returns Cells */
            foreach (Cell? c in array) {
                bool highlight = c.same_place (current_cell);
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
        /* Construct cell beneath pointer */
        Cell cell = {r, c, array.get_data_from_rc (r, c)};
        if (!cell.equal (current_cell)) {
            if (current_cell == null) {
                previous_cell = null;
            } else {
                previous_cell = current_cell.clone ();
            }
            current_cell = cell.clone ();
        }

        return;
    }

    private void draw_grid (Cairo.Context cr) {
        Gdk.cairo_set_source_rgba (cr, grid_color);
        cr.set_antialias (Cairo.Antialias.NONE);
        cr.set_line_width (MINOR_GRID_LINE_WIDTH);

        var r = rows;
        var c = cols;
        var w = cell_width;
        var h = cell_height;
        // Draw minor grid lines
        var x2 = w * c;
        var y2 = h * r;
        // Draw horizontal lines
        for (int cell = 0; cell < r; cell++) {
            var y1 = cell * h;
            cr.move_to (0, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
        }

        // Draw vertical lines
        for (int cell = 0; cell < c; cell++) {
            var x1 = cell * w;
            cr.move_to (x1, 0);
            cr.line_to (x1, y2);
            cr.stroke ();
        }

        // Draw inner major grid lines
        cr.set_line_width (MAJOR_GRID_LINE_WIDTH);
        // Draw horizontal lines
        for (int cell = 5; cell < r; cell += 5) {
            var y1 = cell * h;
            cr.move_to (0, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
        }

        // Draw vertical lines
        for (int cell = 5; cell < c; cell += 5) {
            var x1 = cell * w;
            cr.move_to (x1, 0);
            cr.line_to (x1, y2);
            cr.stroke ();
        }

        // Draw frame
        cr.set_line_width (MINOR_GRID_LINE_WIDTH);
        var y1 = MINOR_GRID_LINE_WIDTH;
        var x1 = MINOR_GRID_LINE_WIDTH;
        cr.move_to (x1, y1);
        cr.line_to (x2 - x1, y1);
        cr.stroke ();

        cr.move_to (x2 - x1, y1);
        cr.line_to (x2 - x1, y2 - y1);
        cr.stroke ();

        cr.move_to (x2 - x1, y2 - y1);
        cr.line_to (x1, y2 - y1);
        cr.stroke ();

        cr.move_to (x1, y2 - y1);
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
            cr.rectangle (x, y, cell_width, cell_height);
            cr.clip ();
            cr.set_source (highlight_pattern.pattern);
            cr.set_operator (Cairo.Operator.OVER);
            cr.paint ();
            cr.restore ();
        }
    }

    private void on_leave_notify () {
        previous_cell = null;
        current_cell = null;
        leave ();
        return;
    }
}
