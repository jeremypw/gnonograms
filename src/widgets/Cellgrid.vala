/* Draws grid of cells and detects pointer motion over it.
 * Copyright (C) 2010-2017  Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author:
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */

namespace Gnonograms {
public class CellGrid : Gtk.DrawingArea {
    /*** PUBLIC ***/

    public signal void cursor_moved (Cell from, Cell to);

    public Model? model { get; construct; }
    public Cell current_cell { get; set; }
    public Cell previous_cell { get; set; }
    public bool frozen { get; set; }

    /* Could have more options for cell pattern - only plain implemented for elementaryos*/
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

    public GameState game_state { /* Do we need different colors for game state? */
        set {
            unknown_color = colors[(int)value, (int)CellState.UNKNOWN];
            fill_color = colors[(int)value, (int)CellState.FILLED];
            empty_color = colors[(int)value, (int)CellState.EMPTY];
            cell_pattern_type = CellPatternType.UNDEFINED; /* Causes refresh of existing pattern */
        }
    }
    /*---------------------------------------------------------*/

    /*** PRIVATE ***/
    private const double MAJOR_GRID_LINE_WIDTH = 3.0;
    private const double MINOR_GRID_LINE_WIDTH = 1.0;
    private Gdk.RGBA[, ] colors;

    private uint rows {
        get {
            assert (model != null);
            return model != null ? model.rows : 0;
        }
    }
    private uint cols {
        get {
            return model != null ? model.cols : 0;
        }
    }

    /* Backing variable; do not assign directly */
    private CellPatternType _cell_pattern_type;
    /*------------------------------------------*/

    private bool dirty = false; /* Whether a redraw is needed */
    private double alloc_width; /* Width of drawing area less frame*/
    private double alloc_height; /* Height of drawing area less frame */
    private double cell_body_width; /* Width of cell excluding frame */
    private double cell_body_height; /* height of cell excluding frame */
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

    private void set_colors () { /* TODO simplify by having same colors for setting and solving, derived from theme */
        int setting = (int)GameState.SETTING;
        colors[setting, (int)CellState.UNKNOWN].parse (Gnonograms.UNKNOWN_COLOR);
        colors[setting, (int)CellState.EMPTY].parse (Gnonograms.SETTING_EMPTY_COLOR);
        colors[setting, (int)CellState.FILLED].parse (Gnonograms.SETTING_FILLED_COLOR);

        int solving = (int)GameState.SOLVING;
        colors[solving, (int)CellState.UNKNOWN].parse (Gnonograms.UNKNOWN_COLOR);
        colors[solving, (int)CellState.EMPTY].parse (Gnonograms.SOLVING_EMPTY_COLOR);
        colors[solving, (int)CellState.FILLED].parse (Gnonograms.SOLVING_FILLED_COLOR);
    }

    private My2DCellArray? array {
        get {
            if (model != null) {
                return model.display_data;
            } else {
                return null;
            }
        }
    } /* model display data */

    /*---------------------------------------------------------*/
    public CellGrid (Model model) {
        Object (model: model);
    }

    construct {
        _current_cell = NULL_CELL;
        colors = new Gdk.RGBA[2, 3];
        grid_color.parse (Gnonograms.GRID_COLOR);
        game_state = GameState.SETTING;
        cell_pattern_type = CellPatternType.CELL;
        set_colors ();

        this.add_events (
            Gdk.EventMask.BUTTON_PRESS_MASK|
            Gdk.EventMask.BUTTON_RELEASE_MASK|
            Gdk.EventMask.POINTER_MOTION_MASK|
            Gdk.EventMask.KEY_PRESS_MASK|
            Gdk.EventMask.KEY_RELEASE_MASK|
            Gdk.EventMask.LEAVE_NOTIFY_MASK
        );

        motion_notify_event.connect (on_pointer_moved);
        draw.connect (on_draw_event);
        size_allocate.connect (on_size_allocate);
        leave_notify_event.connect (on_leave_notify);

        notify["current-cell"].connect (() => {
            queue_draw ();
        });

        model.notify["dimensions"].connect (dimensions_updated);

        model.changed.connect (() => {
            if (!dirty) {
                dirty = true;
                queue_draw ();
            }
        });
    }

/*************/
/** PRIVATE **/
/*************/


/*** Signal Handlers ***/
    private void on_size_allocate (Gtk.Allocation rect) {
        alloc_width = (double)(rect.width);
        alloc_height = (double)(rect.height);
        dimensions_updated ();
    }

    private void dimensions_updated () {
        cell_width = (alloc_width) / (double)cols;
        cell_height = (alloc_height) / (double)rows;
        cell_body_width = cell_width;
        cell_body_height = cell_height;
        /* Cause refresh of existing pattern */
        highlight_pattern = new CellPattern.highlight (cell_width, cell_height);
    }

    private bool on_draw_event (Cairo.Context cr) {
        dirty = false;

        if (array != null) {
            /* Note, even tho' array holds CellStates, its iterator returns Cells */
            foreach (Cell c in array) {
                bool highlight = (c.row == current_cell.row && c.col == current_cell.col);
                draw_cell (cr, c, highlight);
            }
        }

        draw_grid (cr);
        return true;
    }

    private bool on_pointer_moved (Gdk.EventMotion e) {
        if (e.x < 0 || e.y < 0) {
            return false;
        }
        /* Calculate which cell the pointer is over */
        uint r = ((uint)((e.y) / cell_height));
        uint c = ((uint)(e.x / cell_width));

        if (r >= rows || c >= cols) {
            return true;
        }
        /* Construct cell beneath pointer */
        Cell cell = {r, c, array.get_data_from_rc (r, c)};

        if (!cell.equal (current_cell)) {
            update_current_cell (cell);
        }

        return true;
    }

/*** --------------------------------------------------- ***/
    private void update_current_cell (Cell target) {
        previous_cell = current_cell.clone ();
        current_cell = target.clone ();
    }

    private void draw_grid (Cairo.Context cr) {
        double x1, x2, y1, y2;

        Gdk.cairo_set_source_rgba (cr, grid_color);
        cr.set_antialias (Cairo.Antialias.NONE);

        //Draw minor grid
        cr.set_line_width (MINOR_GRID_LINE_WIDTH);

        // Horizontal lines
        y1 = 0;
        x1 = 0; x2 = alloc_width;

        while (y1 < alloc_height) {
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
            y1 += cell_height;
        }

        // Vertical lines
        x1 = 0;
        y1 = 0; y2 = alloc_height;

        while (x1 < alloc_width) {
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
            x1 += cell_width;

        }

        // Draw major grid
        cr.set_line_width (MAJOR_GRID_LINE_WIDTH);

        // Horizontal lines
        y1 = 0;
        x1 = 0; x2 = alloc_width;

        while (y1 < alloc_height) {
            y1 += 5.0 * cell_height;
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
        }

        // Vertical lines
        x1 = 0;
        y1 = 0; y2 = alloc_height;

        while (x1 < alloc_width) {
            x1 += 5.0 * cell_width;
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
        }

        // Draw frame
        cr.set_line_width (MAJOR_GRID_LINE_WIDTH);
        // Horizontal lines
        y1 = MAJOR_GRID_LINE_WIDTH / 2;
        x1 = 0; x2 = alloc_width;
        cr.move_to (x1, y1);
        cr.line_to (x2, y1);
        cr.stroke ();

        y1 = alloc_height - MAJOR_GRID_LINE_WIDTH / 2;
        cr.move_to (x1, y1);
        cr.line_to (x2, y1);
        cr.stroke ();

        x1 = MAJOR_GRID_LINE_WIDTH / 2;
        y1 = 0; y2 = alloc_height;
        cr.move_to (x1, y1);
        cr.line_to (x1, y2);
        cr.stroke ();

        x1 = alloc_width - MAJOR_GRID_LINE_WIDTH / 2;
        cr.move_to (x1, y1);
        cr.line_to (x1, y2);
        cr.stroke ();

    }

    private void draw_cell (Cairo.Context cr, Cell cell, bool highlight = false, bool mark = false) {
        /*  Calculate coords of top left corner of filled part
         *  (excluding grid if present but including highlight line)
         */

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
        cr.rectangle (x, y, cell_body_width, cell_body_height);
        cr.set_source (cell_pattern.pattern);
        cr.fill ();
        cr.restore ();

        if (highlight) {
            cr.save ();
            /* Ensure highlight centred and slightly overlapping grid */
            highlight_pattern.move_to (x, y);
            cr.rectangle (x, y, cell_body_width, cell_body_width);
            cr.clip ();
            cr.set_source (highlight_pattern.pattern);
            cr.set_operator (Cairo.Operator.OVER);
            cr.paint ();
            cr.restore ();
        }
    }

    private bool on_leave_notify () {
        previous_cell = NULL_CELL;
        current_cell = NULL_CELL;
        return false;
    }

/*** Private classes ***/

    private class CellPattern: GLib.Object {
        public Cairo.Pattern pattern;
        public double size { get; private set; }

        public CellPattern.cell (Gdk.RGBA color) {
            double red = color.red;
            double green = color.green;
            double blue = color.blue;
            pattern = new Cairo.Pattern.rgba (red, green, blue, 1.0);
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
            pattern.set_matrix (matrix);

        }

        construct {
            matrix = Cairo.Matrix.identity ();
        }

        public void move_to (double x, double y) {
            var xx = x - x0;
            var yy = y - y0;
            matrix.translate (-xx, -yy);
            pattern.set_matrix (matrix);
            x0 = x;
            y0 = y;
        }

        private double x0 = 0;
        private double y0 = 0;
        private Cairo.Matrix matrix;
    }
}
}
