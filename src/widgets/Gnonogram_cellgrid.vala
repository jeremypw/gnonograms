/* Draws grid of cells and detects pointer motion over it.
 * Copyright (C) 2010-2011  Jeremy Wootten
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

namespace Gnonograms {
public class CellGrid : Gtk.DrawingArea {
    public signal void cursor_moved (int r, int c);

    private int rows {get { return dimensions.height; }}
    private int cols {get { return dimensions.width; }}
    private int current_col;
    private double _aw;
    private double _ah;
    private double _wd;
    private double _ht;
    private double cell_offset;
    private double cell_body_width; /* TODO simplify by ensuring square only */
    private double cell_body_height;
    private Gdk.RGBA grid_color;

    private CellPattern filled_cell_pattern;
    private CellPattern empty_cell_pattern;
    private CellPattern unknown_cell_pattern;

    public CellPatternType cell_pattern_type { /* Do we need more than one pattern? */
        set {
            switch (value) {
                case CellPatternType.RADIAL:
                    filled_cell_pattern = new CellPattern.radial (cell_body_width, cell_body_height, fill_color);
                    empty_cell_pattern = new CellPattern.radial (cell_body_width, cell_body_height, empty_color);
                    unknown_cell_pattern = new CellPattern.gdk_rgba (unknown_color);
                    break;

                default:
                    filled_cell_pattern = new CellPattern.gdk_rgba (fill_color);
                    empty_cell_pattern = new CellPattern.gdk_rgba (empty_color);
                    unknown_cell_pattern = new CellPattern.gdk_rgba (unknown_color);
                    break;
            }
        }
    }

    private Cairo.Matrix pattern_matrix;

    private Gdk.RGBA[, ] colors;

    private Gdk.RGBA fill_color;
    private Gdk.RGBA empty_color;
    private Gdk.RGBA unknown_color;

    private double[] MINORGRIDDASH;

    public My2DCellArray array {get; set;}

    public GameState game_state  { /* Do we need different colors for game state? */
        set {
            unknown_color = colors[(int)value, (int)CellState.UNKNOWN];
            fill_color = colors[(int)value, (int)CellState.FILLED];
            empty_color = colors[(int)value, (int)CellState.EMPTY];
        }
    }

    public Dimensions dimensions {get; set;}

    construct {
        colors = new Gdk.RGBA[2, 4];
        set_colors ();
        MINORGRIDDASH = {3.0, 3.0};
        current_col = -1;
        cell_offset = -1;

        this.add_events (
        Gdk.EventMask.BUTTON_PRESS_MASK|
        Gdk.EventMask.BUTTON_RELEASE_MASK|
        Gdk.EventMask.POINTER_MOTION_MASK|
        Gdk.EventMask.KEY_PRESS_MASK|
        Gdk.EventMask.KEY_RELEASE_MASK|
        Gdk.EventMask.LEAVE_NOTIFY_MASK
        );

        motion_notify_event.connect (pointer_moved);
        leave_notify_event.connect (leave_grid);

        draw.connect (on_draw_event);

        grid_color.parse ("BLACK");

        game_state = GameState.SETTING;
        cell_pattern_type = CellPatternType.NONE;
    }

    public CellGrid (Dimensions dimensions) {
        Object (dimensions: dimensions);
    }


    public bool on_draw_event (Cairo.Context cr) {
        redraw_all (cr);
        return true;
    }

    private void redraw_all (Cairo.Context cr) {
        prepare_to_redraw_cells (cr);

        if (array != null) {
            foreach (Cell c in array) {
                draw_cell (cr, c);
            }
        }

        draw_grid (cr);
    }

    public void prepare_to_redraw_cells (Cairo.Context cr) {
        Gtk.Allocation allocation;
        get_allocation (out allocation);
        _aw =  (double)allocation.width;
        _ah =  (double)allocation.height;
        _wd =  (_aw - 2) / (double)cols;
        _ht =  (_ah - 2) / (double)rows;
        cell_body_width = _wd - CELLOFFSET_WITHGRID - 1.0;
        cell_body_height = _ht - CELLOFFSET_WITHGRID - 1.0;
    }

    public void draw_cell (Cairo.Context cr, Cell cell, bool highlight = false, bool mark = false) {
        /*  Calculate coords of top left corner of filled part
         *  (excluding grid if present but including highlight line)
         */
        double x = cell.col * _wd + CELLOFFSET_WITHGRID;
        double y =  cell.row * _ht + CELLOFFSET_WITHGRID;
        bool error = false;
        CellPattern pattern;

        switch (cell.state) {
            case CellState.ERROR_EMPTY:
            case CellState.EMPTY:
                pattern = empty_cell_pattern;
                error = (cell.state == CellState.ERROR_EMPTY);
                break;

            case CellState.ERROR_FILLED:
            case CellState.FILLED:
                pattern = filled_cell_pattern;
                error = (cell.state == CellState.ERROR_FILLED);
                break;

            default :
                pattern = unknown_cell_pattern;
                break;
        }

        pattern_matrix = Cairo.Matrix.identity ();
        pattern_matrix.translate (-x, -y);
        pattern.pattern.set_matrix (pattern_matrix);

        /* Draw cell body */
        cr.set_line_width (0.5);
        cr.rectangle (x, y, cell_body_width, cell_body_height);
        cr.set_source (pattern.pattern);
        cr.fill ();

        if (mark) {
            cr.set_line_width (1.0);
            Gdk.cairo_set_source_rgba (cr, (this.get_style_context ()).get_background_color (Gtk.StateFlags.SELECTED));

            cr.rectangle (x + cell_body_width / 4,
                          y + cell_body_height / 4,
                          cell_body_width / 2,
                          cell_body_height / 2);

            cr.fill ();
        }

        if (error) { /* TODO Simplify by not marking erroneous cells */
            cr.set_line_width (4.0);
            Gdk.cairo_set_source_rgba (cr, colors[0, (int) CellState.ERROR]);

            cr.rectangle (x + 3,
                          y + 3,
                          cell_body_width - 6,
                          cell_body_height - 6);

            cr.stroke ();
        } else if (highlight) {
            cr.set_line_width (2.0);
            var sc = this.get_style_context ();
            Gdk.cairo_set_source_rgba (cr, sc.get_background_color (Gtk.StateFlags.SELECTED));

            cr.rectangle (x + 2,
                          y + 2,
                          cell_body_width - 4,
                          cell_body_height - 4);

            cr.stroke ();
        }
    }

    public void draw_grid (Cairo.Context cr) {
        double x1, x2, y1, y2;

        Gdk.cairo_set_source_rgba (cr, grid_color);
        cr.set_antialias (Cairo.Antialias.NONE);

        //Draw minor grid (dashed lines)
        cr.set_dash (MINORGRIDDASH, 0.0);
        cr.set_line_width (1.0);

        x1 = 0; x2 = _aw - 1;
        y1 = 1.0;
        uint r = 0;
        while (r < rows) {
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
            y1 += _ht;
            r++;
        }

        y1 = 0; y2 = _ah - 1;
        x1 = 1.0;
        uint c = 0;
        while (c < cols) {
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
            x1 += _wd;
            c++;
        }

        //Draw major grid (solid lines)
        cr.set_dash (null, 0.0);
        cr.set_line_width (2.0);

        x1 = 0; x2 = _aw - 1;
        y1 = 1.0;
        r = 0;
        double inc = 5 * _ht;
        while (r <= rows) {
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
            y1 += inc;
            r += 5;
        }

        y1 = 0; y2 = _ah - 1;
        x1 = 1.0;
        c = 0;
        inc = 5 * _wd;
        while (c <= cols) {
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
            x1 += inc;
            c += 5;
        }
    }

    private bool pointer_moved (Gdk.EventMotion e) {
        /* Calculate which cell the pointer is over */
        int r =  ((int)(e.y / _ah * rows)).clamp (0, rows - 1); /* TODO store rows / _ah */
        int c =  ((int)(e.x / _aw * cols)).clamp (0, cols - 1); /* TODO store cols / _aw */

        if (c != current_col || r != cell_offset) { /* only signal when cursor changes cell */
            cursor_moved (r, c); /* signal handled by Gnonograms.Controller */
        }

        return true;
    }

    private bool leave_grid (Gdk.EventCrossing e) {
        if (e.x < 0 || e.y < 0) { //ignore false leave events that sometimes occur for unknown reason
            cursor_moved (-1, -1);
        }

        return true;
    }

    private void set_colors () {  /* TODO simplify by having same colors for setting and solving, derived from theme */
        int setting = (int)GameState.SETTING;
        colors[setting, (int)CellState.UNKNOWN].parse ("LIGHT GREY");
        colors[setting, (int)CellState.EMPTY].parse ("WHITE");
        colors[setting, (int)CellState.FILLED].parse ("BLACK");
        colors[setting, (int)CellState.ERROR].parse ("RED");

        int solving = (int)GameState.SOLVING;
        colors[solving, (int)CellState.UNKNOWN].parse ("LIGHT GREY");
        colors[solving, (int)CellState.EMPTY].parse ("YELLOW");
        colors[solving, (int)CellState.FILLED].parse ("BLUE");
        colors[solving, (int)CellState.ERROR].parse ("RED");
    }

    private class CellPattern {
        public Cairo.Pattern pattern;

        public CellPattern.gdk_rgba (Gdk.RGBA cc) {
            double red = cc.red;
            double green = cc.green;
            double blue = cc.blue;
            pattern = new Cairo.Pattern.rgba (red, green, blue, 1.0);
        }

        public CellPattern.radial (double wd, double ht, Gdk.RGBA cc) {
            double red = cc.red;
            double green = cc.green;
            double blue = cc.blue;
            pattern = new Cairo.Pattern.radial (wd * 0.25, ht * 0.25, 0.0, wd * 0.5, ht * 0.5, wd * 0.5-1.0);
            pattern.add_color_stop_rgba (0.0, 1.0, 1.0, 1.0, 1.0);
            pattern.add_color_stop_rgba (0.99, red, green, blue, 1.0);
            pattern.add_color_stop_rgba (1.0, 0.0, 0.0, 0.0, 0.5);
            pattern.add_color_stop_rgba (1.0, 0.9, 0.9, 0.9, 1.0);
        }
    }
}
}
