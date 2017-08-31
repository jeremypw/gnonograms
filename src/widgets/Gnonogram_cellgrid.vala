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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {
public class CellGrid : Gtk.DrawingArea {
    public signal void cursor_moved (Cell from, Cell to);

    public Model? model { get; set; }

    public My2DCellArray? array {
        get {
            if (model != null) {
                return model.display_data;
            } else {
                return null;
            }
        }
    } /* model display data */

    public unowned Cell current_cell {
        get {
            return _current_cell;
        }

        set {
            _current_cell.copy (value);
        }
    }

    public double cell_width { get; private set; } /* Width of cell including frame */
    public double cell_height { get; private set; } /* Height of cell including frame */

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

    public GameState game_state  { /* Do we need different colors for game state? */
        set {
            unknown_color = colors[(int)value, (int)CellState.UNKNOWN];
            fill_color = colors[(int)value, (int)CellState.FILLED];
            empty_color = colors[(int)value, (int)CellState.EMPTY];

            cell_pattern_type = CellPatternType.UNDEFINED; /* Causes refresh of existing pattern */

            queue_draw ();
        }
    }

    public CellGrid (Model model) {
        Object (model: model);
    }

    construct {
        _current_cell = NULL_CELL;
        colors = new Gdk.RGBA[2, 4];
        grid_color.parse ("GREY");
        game_state = GameState.SETTING;
        cell_pattern_type = CellPatternType.CELL;
        set_colors ();

        this.add_events (
            Gdk.EventMask.BUTTON_PRESS_MASK|
            Gdk.EventMask.BUTTON_RELEASE_MASK|
            Gdk.EventMask.POINTER_MOTION_MASK|
            Gdk.EventMask.KEY_PRESS_MASK|
            Gdk.EventMask.KEY_RELEASE_MASK|
            Gdk.EventMask.LEAVE_NOTIFY_MASK|
            Gdk.EventMask.SCROLL_MASK
        );

        motion_notify_event.connect (on_pointer_moved);
        draw.connect (on_draw_event);
        size_allocate.connect (on_size_allocate);
        leave_notify_event.connect (on_leave_notify);
    }

    public void highlight_cell (Cell cell, bool highlight) {
        if (cell.equal (NULL_CELL)) {
            return;
        }

#if HAVE_GDK_3_22
        var dc = this.window ().begin_draw_frame (new Cairo.Region ());
        cr = dc.get_cairo_context ();
#else
        var cr = Gdk.cairo_create (this.get_window ());
#endif
        cell.state = array.get_data_from_rc (cell.row, cell.col);
        draw_cell (cr, cell, highlight);
        draw_grid (cr);

#if HAVE_GDK_3_22
        this.window ().end_draw_frame ();
#endif
    }

    public void move_cursor_relative (int row_delta, int col_delta) {
        if (current_cell == NULL_CELL) {
            return;
        }

        if (row_delta != 0 || col_delta != 0) {
            Cell target = {current_cell.row + row_delta,
                           current_cell.col + col_delta,
                           CellState.UNDEFINED
                          };

            if (target.row >= rows || target.col >= cols) {
                return;
            }

            move_cursor_to (target);
        }
    }

/*************/
/** PRIVATE **/
/*************/
    private const double CELL_FRAME_WIDTH = 0.0;
    private const double HIGHLIGHT_WIDTH = 2.0;
    private const double MAJOR_GRID_LINE_WIDTH = 2.0;
    private const double MINOR_GRID_LINE_WIDTH = 1.0;
    private Gdk.RGBA[, ] colors;

    private uint rows {get { return model != null ? model.rows : 0; }}
    private uint cols {get { return model != null ? model.cols : 0; }}

    /* Backing variable; do not assign directly */
    private Cell _current_cell;
    private CellPatternType _cell_pattern_type;
    /*------------------------------------------*/

    private double alloc_width; /* Width of drawing area less frame*/
    private double alloc_height; /* Height of drawing area less frame */
    private double cell_body_width; /* Width of cell excluding frame */
    private double cell_body_height; /* height of cell excluding frame */

    private Gdk.RGBA grid_color;
    private Gdk.RGBA fill_color;
    private Gdk.RGBA empty_color;
    private Gdk.RGBA unknown_color;

    private CellPattern filled_cell_pattern;
    private CellPattern empty_cell_pattern;
    private CellPattern unknown_cell_pattern;
    private CellPattern highlight_pattern;

    private void set_colors () {  /* TODO simplify by having same colors for setting and solving, derived from theme */
        int setting = (int)GameState.SETTING;
        colors[setting, (int)CellState.UNKNOWN].parse ("LIGHT GREY");
        colors[setting, (int)CellState.EMPTY].parse ("WHITE");
        colors[setting, (int)CellState.FILLED].parse ("DARK GREY");
        colors[setting, (int)CellState.ERROR].parse ("RED");

        int solving = (int)GameState.SOLVING;
        colors[solving, (int)CellState.UNKNOWN].parse ("LIGHT GREY");
        colors[solving, (int)CellState.EMPTY].parse ("YELLOW");
        colors[solving, (int)CellState.FILLED].parse ("BLUE");
        colors[solving, (int)CellState.ERROR].parse ("RED");
    }

/*** Signal Handlers ***/
    private void on_size_allocate (Gtk.Allocation rect) {
        alloc_width = (double)(rect.width);
        alloc_height = (double)(rect.height);
        cell_width = (alloc_width) / (double)cols;
        cell_height = (alloc_height) / (double)rows;
        cell_body_width = cell_width;
        cell_body_height = cell_height;
        /* Cause refresh of existing pattern */
        highlight_pattern = new CellPattern.highlight (cell_width, cell_height);
    }


    private bool on_draw_event (Cairo.Context cr) {
        if (array != null) {
            /* Note, even tho' array holds CellStates, its iterator returns Cells */
            foreach (Cell c in array) {
                draw_cell (cr, c);
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
        uint r =  ((uint)((e.y) / cell_height));
        uint c =  ((uint)(e.x / cell_width));
        /* Construct cell beneath pointer */
        Cell cell = {r, c, array.get_data_from_rc (r, c)};

        move_cursor_to (cell);

        return true;
    }

/*** --------------------------------------------------- ***/

    private void move_cursor_to (Cell target) {
        if (target.row >= rows || target.col >= cols) {
            target = NULL_CELL;
        }

        if (!target.equal (current_cell)) { /* only signal when cursor changes cell */
            highlight_cell (current_cell, false);
            highlight_cell (target, true);
            cursor_moved (current_cell, target);
            current_cell = target.clone ();
        }
    }

    private void draw_grid (Cairo.Context cr) {
        double x1, x2, y1, y2;

        double inc = (alloc_height - MINOR_GRID_LINE_WIDTH) / (double)rows;


        Gdk.cairo_set_source_rgba (cr, grid_color);
        cr.set_antialias (Cairo.Antialias.NONE);


        //Draw minor grid (dashed lines)
        cr.set_line_width (1.0);
        x1 = 0; x2 = alloc_width - 1;

        for (int r = 0; r <= rows; r++) {
            y1 = 1.0 + r * cell_height;
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
        }

        y1 = 0; y2 = alloc_height - 1;

        for (int c = 0; c <= cols; c++) {
            x1 = 1.0 + c * cell_width;
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
        }

        //Draw major grid (solid lines)
        cr.set_dash (null, 0.0);
        cr.set_line_width (MAJOR_GRID_LINE_WIDTH);
        uint r = 0;
        uint c = 0;

        /* Draw horizontal lines */
        y1 = MAJOR_GRID_LINE_WIDTH / 2;
        x1 = 0; x2 = alloc_width;
        r = 0;
        inc = 5.0 * ((alloc_height - MAJOR_GRID_LINE_WIDTH) / (double)rows);

        while (r <= rows) {
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
            y1 += inc;
            r += 5;
        }

        /* Draw vertical lines */
        x1 = MAJOR_GRID_LINE_WIDTH / 2;
        y1 = 0; y2 = alloc_height;
        c = 0;
        inc = 5.0 * ((alloc_width - MAJOR_GRID_LINE_WIDTH) / (double)cols);

        while (c <= cols) {
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
            x1 += inc;
            c += 5;
        }
    }

    private void draw_cell (Cairo.Context cr, Cell cell, bool highlight = false, bool mark = false) {
        /*  Calculate coords of top left corner of filled part
         *  (excluding grid if present but including highlight line)
         */
        double x = cell.col * cell_width;
        double y =  cell.row * cell_height;

        bool error = false;
        CellPattern cell_pattern;

        switch (cell.state) {
            case CellState.ERROR_EMPTY:
            case CellState.EMPTY:
                cell_pattern = empty_cell_pattern;
                error = (cell.state == CellState.ERROR_EMPTY);
                break;

            case CellState.ERROR_FILLED:
            case CellState.FILLED:
                cell_pattern = filled_cell_pattern;
                error = (cell.state == CellState.ERROR_FILLED);
                break;

            default :
                cell_pattern = unknown_cell_pattern;
                break;
        }

        /* Draw cell body */
        cell_pattern.move_to (x, y); /* Not needed for plain fill, but may use a pattern later */
        cr.set_line_width (0.5);
        cr.rectangle (x, y, cell_body_width, cell_body_height);
        cr.set_source (cell_pattern.pattern);
        cr.fill ();

        if (highlight) {
            highlight_pattern.move_to (x, y);
            cr.rectangle (x, y, cell_body_width, cell_body_height);
            cr.set_source (highlight_pattern.pattern);
            cr.set_operator (Cairo.Operator.OVER);
            cr.fill ();
        }
    }

    private bool on_leave_notify () {
        highlight_cell (current_cell, false);
        current_cell = NULL_CELL;
        return false;
    }

/*** Private classes ***/

    private class CellPattern: GLib.Object {
        public Cairo.Pattern pattern;

        public CellPattern.cell (Gdk.RGBA color) {
            double red = color.red;
            double green = color.green;
            double blue = color.blue;
            pattern = new Cairo.Pattern.rgba (red, green, blue, 1.0);
        }

        public CellPattern.highlight (double wd, double ht) {
            var r = (wd + ht) / 4.0;

            pattern = new Cairo.Pattern.radial (r, r, 0.0, r, r, r * 1.1);
            pattern.add_color_stop_rgba (0.0, 1.0, 1.0, 1.0, 0.1);
            pattern.add_color_stop_rgba (0.95, 1.0, 1.0, 1.0, 0.2);
            pattern.add_color_stop_rgba (1.0, 0.0, 0.0, 0.0, 1.0);

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
