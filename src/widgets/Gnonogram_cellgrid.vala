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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

namespace Gnonograms {
public class CellGrid : Gtk.DrawingArea {
    private const double CELL_FRAME_WIDTH = 2.0;
    private const double HIGHLIGHT_WIDTH = 2.0;
    private double[] MINORGRIDDASH;
    private const double MAJOR_GRID_LINE_WIDTH = 2.0;
    private const double MINOR_GRID_LINE_WIDTH = 1.0;
    private Gdk.RGBA[, ] colors;

    public Model model {get; set;}
    public My2DCellArray array {
        get {
            return model.display_data;
        }
    } /* model display data */
    private uint rows {get { return array.rows; }}
    private uint cols {get { return array.cols; }}

    private Cell current_cell;

    private double alloc_width; /* Width of drawing area less frame*/
    private double alloc_height; /* Height of drawing area less frame */
    private double cell_width; /* Width of cell including frame */
    private double cell_height; /* Height of cell including frame */
    private double cell_body_width; /* Width of cell excluding frame */
    private double cell_body_height; /* height of cell excluding frame */

    private Gdk.RGBA grid_color;
    private Gdk.RGBA fill_color;
    private Gdk.RGBA empty_color;
    private Gdk.RGBA unknown_color;

    private CellPattern filled_cell_pattern;
    private CellPattern empty_cell_pattern;
    private CellPattern unknown_cell_pattern;

    private CellPatternType _cell_pattern_type;
    public CellPatternType cell_pattern_type { /* Do we need more than one pattern? */
        set {
            switch (value) {
                case CellPatternType.RADIAL: /* Circular fill */
                    filled_cell_pattern = new CellPattern.radial (cell_body_width, cell_body_height, fill_color);
                    empty_cell_pattern = new CellPattern.radial (cell_body_width, cell_body_height, empty_color);
                    unknown_cell_pattern = new CellPattern.gdk_rgba (unknown_color);
                    _cell_pattern_type = value;
                    break;

                    case CellPatternType.NONE: /* plain color fill */
                    filled_cell_pattern = new CellPattern.gdk_rgba (fill_color);
                    empty_cell_pattern = new CellPattern.gdk_rgba (empty_color);
                    unknown_cell_pattern = new CellPattern.gdk_rgba (unknown_color);
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

    public signal void cursor_moved (Cell destination);

    construct {
        colors = new Gdk.RGBA[2, 4];
        set_colors ();
        MINORGRIDDASH = {1.0, 5.0};

        current_cell = NULL_CELL;

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

        grid_color.parse ("BLACK");

        game_state = GameState.SETTING;
        cell_pattern_type = CellPatternType.NONE;

        size_allocate.connect (on_size_allocate);
        leave_notify_event.connect (on_leave_notify);
    }

    public CellGrid (Model model) {
        Object (model: model);
    }

    public bool on_draw_event (Cairo.Context cr) {
        if (array != null) {
            foreach (Cell c in array) { /* Note, even tho' array holds CellStates, its iterator returns Cells */
                draw_cell (cr, c);
            }
        }

        draw_grid (cr);
        return true;
    }

    public void highlight_cell (Cell cell, bool highlight) {
        if (cell == NULL_CELL) {
            return;
        }

        var cr = Gdk.cairo_create (this.get_window ());
        cell.state = array.get_data_from_rc (cell.row, cell.col);
        draw_cell (cr, cell, highlight);
    }
    public void draw_cell (Cairo.Context cr, Cell cell, bool highlight = false, bool mark = false) {
        /*  Calculate coords of top left corner of filled part
         *  (excluding grid if present but including highlight line)
         */
        double x = cell.col * cell_width + CELL_FRAME_WIDTH;
        double y =  cell.row * cell_height + CELL_FRAME_WIDTH;
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

        var pattern_matrix = Cairo.Matrix.identity();
        pattern_matrix.translate (-x,-y);
        cell_pattern.pattern.set_matrix (pattern_matrix);

        /* Draw cell body */
        cr.set_line_width (0.5);
        cr.rectangle (x, y, cell_body_width, cell_body_height);
        cr.set_source (cell_pattern.pattern);
        cr.fill ();

        if (highlight) {
            cr.set_line_width (HIGHLIGHT_WIDTH);
            var sc = this.get_style_context ();
            var color = sc.get_color (Gtk.StateFlags.PRELIGHT);
            cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
            cr.rectangle (x + HIGHLIGHT_WIDTH / 2.0,
                          y + HIGHLIGHT_WIDTH / 2.0,
                          cell_body_width - HIGHLIGHT_WIDTH,
                          cell_body_height - HIGHLIGHT_WIDTH);

            cr.stroke ();
        }
    }

    public void draw_grid (Cairo.Context cr) {
        double x1, x2, y1, y2;

        Gdk.cairo_set_source_rgba (cr, grid_color);
        cr.set_antialias (Cairo.Antialias.NONE);

        //Draw minor grid (dashed lines)
        cr.set_dash (MINORGRIDDASH, 0.0);
        cr.set_line_width (MINOR_GRID_LINE_WIDTH);

        /* Horizontal lines */
        y1 = MINOR_GRID_LINE_WIDTH / 2;
        x1 = 0; x2 = alloc_width;
        uint r = 0;
        double inc = (alloc_height - MINOR_GRID_LINE_WIDTH) / (double)rows;

        while (r < rows) {
            cr.move_to (x1, y1);
            cr.line_to (x2, y1);
            cr.stroke ();
            y1 += inc;
            r++;
        }

        /* Vertical lines */
        x1 = MINOR_GRID_LINE_WIDTH / 2;
        y1 = 0; y2 = alloc_height;
        uint c = 0;
        inc = (alloc_width - MINOR_GRID_LINE_WIDTH) / (double)cols;

        while (c < cols) {
            cr.move_to (x1, y1);
            cr.line_to (x1, y2);
            cr.stroke ();
            x1 += inc;
            c++;
        }

        //Draw major grid (solid lines)
        cr.set_dash (null, 0.0);
        cr.set_line_width (MAJOR_GRID_LINE_WIDTH);

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
    public void on_size_allocate (Gtk.Allocation rect) {
        alloc_width = (double)(rect.width);
        alloc_height = (double)(rect.height);
        cell_width = (alloc_width) / (double)cols;
        cell_height = (alloc_height) / (double)rows;
        cell_body_width = cell_width - CELL_FRAME_WIDTH - MAJOR_GRID_LINE_WIDTH;
        cell_body_height = cell_height - CELL_FRAME_WIDTH  - MAJOR_GRID_LINE_WIDTH;
    }

    private bool on_pointer_moved (Gdk.EventMotion e) {
        /* Calculate which cell the pointer is over */
        uint r =  ((uint)(e.y / cell_width));
        uint c =  ((uint)(e.x / cell_height));
        move_cursor_to ({r, c, CellState.UNDEFINED});
        return true;
    }

    public void move_cursor_to (Cell target) {
        if (target.row >= rows || target.col >= cols) {
            target = NULL_CELL;
        }

        if (target != current_cell) { /* only signal when cursor changes cell */
            highlight_cell (current_cell, false);
            current_cell.copy (target);
            cursor_moved (current_cell);
            highlight_cell (current_cell, true);
        }
    }

    public void move_cursor_relative (int row_delta, int col_delta) {
        if (current_cell == NULL_CELL) {
            return;
        }

        if (row_delta != 0 || col_delta != 0) {
            Cell target = {current_cell.row + row_delta,
                           current_cell.col + col_delta,
                           CellState.UNDEFINED};

            if (target.row >= rows || target.col >= cols) {
                return;
            }

            move_cursor_to (target);
        }
    }

    private bool on_leave_notify () {
        highlight_cell (current_cell, false);
        current_cell = NULL_CELL;
        return false;
    }

/*** Private classes ***/

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
