/* Handles working and solution data for gnonograms-elementary
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
public class Model : GLib.Object {
    /** PUBLIC **/
    public GameState game_state { get; set; }
    public My2DCellArray solution_data { get; private set; }
    public My2DCellArray working_data { get; private set; }
    public uint rows { get; private set; }
    public uint cols  { get; private set; }

    public Dimensions dimensions {
        set {
            solution_data.dimensions = value;
            working_data.dimensions = value;
            rows = value.height;
            cols = value.width;
        }
    }

    public My2DCellArray display_data  {
        get {
            if (game_state == GameState.SETTING) {
                return solution_data;
            } else {
                return working_data;
            }
        }
    }

    construct {
        rand_gen = new Rand ();
        solution_data = new My2DCellArray ({ MAXSIZE, MAXSIZE }, CellState.EMPTY);
        working_data = new My2DCellArray ({ MAXSIZE, MAXSIZE }, CellState.UNKNOWN);
        data = new CellState[MAXSIZE];
    }

    public void clear_errors() {
        CellState cs;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                cs = working_data.get_data_from_rc (r,c);

                switch (cs) {
                    case CellState.ERROR_EMPTY:
                        working_data.set_data_from_rc (r, c, CellState.EMPTY);
                        break;

                    case CellState.ERROR_FILLED:
                        working_data.set_data_from_rc (r, c, CellState.FILLED);
                        break;

                    default:
                        break;
                }
            }
        }
    }

    public int count_errors() {
        CellState cs;
        int count = 0;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols;c++) {
                cs = working_data.get_data_from_rc (r,c);

                if (cs != CellState.UNKNOWN && cs != solution_data.get_data_from_rc (r, c)) {
                    if (cs == CellState.EMPTY) {
                        working_data.set_data_from_rc (r, c, CellState.ERROR_EMPTY);
                    } else if (cs == CellState.FILLED) {
                        working_data.set_data_from_rc (r,c,CellState.ERROR_FILLED);
                    }

                    count++;
                }
            }
        }

        return count;
    }

    public int count_unsolved () {
        int count=0;
        CellState cs;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                cs = working_data.get_data_from_rc (r,c);
                if (cs == CellState.UNKNOWN || cs == CellState.ERROR) {
                    count++;
                }
            }
        }

        return count;
    }

    public bool is_finished () {
        CellState cs;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                cs = working_data.get_data_from_rc (r,c);
                if (cs == CellState.UNKNOWN || cs == CellState.ERROR) {
                    return false;
                }
            }
        }

        return true;
    }

    public void clear () {
        blank_solution ();
        blank_working ();
    }

    public void blank_solution () {
        solution_data.set_all (CellState.EMPTY);
    }

    public void blank_working () {
        working_data.set_all (CellState.UNKNOWN);
    }

    public string get_label_text (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return solution_data.data2text (idx, length, is_column);
    }

    public void set_data_from_cell (Cell cell) {
        display_data.set_data_from_cell (cell);
    }

    public void set_data_from_rc (uint r, uint c, CellState state) {
        display_data.set_data_from_rc (r, c, state);
    }

    public CellState get_data_for_cell (Cell cell) {
        return display_data.get_data_for_cell (cell);
    }

    public CellState get_data_from_rc (uint r, uint c) {
        return display_data.get_data_from_rc (r, c);
    }

    public bool set_row_data_from_string (int r, string s) {
        CellState[] cs = Utils.cellstate_array_from_string (s);
        return set_row_data_from_data_array (r, cs);
    }

    public bool set_row_data_from_data_array (int r, CellState[] cs) {
        if (cs.length != cols) {
            warning ("Wrong number of columns in data cs length %u, cols %u", cs.length, cols);
            return false;
        } else {
            display_data.set_row (r, cs);
        }

        return true;
    }

    /*** Generate a pseudo-random pattern which is adjusted to be more likely to
       * give a solvable game of the desired difficulty.
    ***/
    public void fill_random (uint grade) {
        clear();
        double rel_g = (double)grade / (double)(Difficulty.MAXIMUM);
        uint g = (uint) (12 * rel_g);
        int midcol = (int)rows / 2;
        int midrow = (int)cols / 2;
        int mincdf = 2 + (int)(((double)rows * rel_g / 4));
        int minrdf = 2 + (int)(((double)cols * rel_g / 4));

        for (uint e = 0; e < data.length; e++) {
            data[e] = CellState.EMPTY;
        }

        int maxb = 1 + (int)((double)cols * (1.0 - rel_g));

        for (int r = 0; r < rows; r++) {
            solution_data.get_row (r, ref data);
            fill_region (cols, ref data, g, (uint)((r - midcol).abs()), maxb, cols);
            solution_data.set_row (r, data);
        }

        maxb = 1 + (int)((double)rows * (1.0 - rel_g));

        for (int c = 0; c < cols; c++) {
            solution_data.get_col (c, ref data);
            fill_region (rows, ref data, g, (c - midrow).abs(), maxb, rows);
            solution_data.set_col (c, data);
        }

        for (uint r = 0; r < rows; r++) {
            solution_data.get_row (r, ref data);
            adjust_region (cols, ref data, minrdf);
            solution_data.set_row (r, data);
        }

        for (uint c = 0; c < cols; c++) {
            solution_data.get_col (c, ref data);
            adjust_region (rows, ref data, mincdf);
            solution_data.set_col (c, data);
        }
    }

    /** PRIVATE **/
    private  CellState[] data;
    private Rand rand_gen;

    private void fill_region (uint size, ref CellState[] data, uint grade, uint e, uint maxb, uint maxp) {
        //e is larger for rows/cols further from edge
        //do not want too many edge cells filled
        //maxb is maximum size of one random block
        //maxp is range of random number generator

        uint p = 0; //pointer
        int mid = (int)size / 2;
        int baseline;
        uint bsize; // blocksize

        if (grade < Difficulty.ADVANCED) {
            maxb = uint.max (2, maxb);
        } else {
            maxb = mid;
        }


        if (grade < Difficulty.ADVANCED) {
            baseline = (int)(e + grade);
        } else {
            baseline = (int)(maxp / 3);
        }
        // baseline relates to the probability of a filled block before
        // adjusting for distance from edge of region.
        bool fill;

        while (p < size) {
            // random choice whether to be full or empty, weighted so
            // less likely to fill squares close to edge
            fill = rand_gen.int_range (0, (int)maxp) > (baseline + ((int)p - mid).abs());

            // random length up to remaining space but not larger than
            // maxb for filled cells or size-maxb for empty cells
            // bsize=int.min(rand_gen.int_range(0,size-p),maxb);
            if (size - p > 1) {
                bsize = uint.min (rand_gen.int_range (1, (int)(size - p)), fill ? maxb : size - maxb);

                for (uint i = 0; i < bsize - 1; i++) {
                    if (fill && i < size -1) {
                        data[p] = CellState.FILLED;
                    }

                    p++;
                }
            }

            p++; //at least one space between blocks

            if (fill && p < size) {
                data[p]=CellState.EMPTY;
            }
        }
    }

    private void adjust_region (uint s, ref CellState [] arr, int mindf) {
        //s is size of region
        // mindf = minimum degrees of freedom
        if (s < 5) {
            return;
        }

        uint b = 0; // count of filled cells
        uint bc = 0; // count of filled blocks
        uint df = 0; // degrees of freedom

        for (int i = 0; i < s; i++) {
            if (arr[i] == CellState.FILLED) {
                b++;

                if (i == 0 || arr[i - 1] == CellState.EMPTY) {
                    bc++;
                }
            }
        }

        df = s - b - bc + 1;

        if (df > s) { //completely empty - fill one cell
            arr[rand_gen.int_range (0, (int)s)] = CellState.FILLED;
        } else {// empty cells until reach min freedom
            int count = 0;

            while (df < mindf && count < 30) {
                count++;
                int i = rand_gen.int_range (1, (int)(s - 1));

                if (arr[i] == CellState.FILLED) {
                    arr[i] = CellState.EMPTY;
                    df++;
                }
            }
        }
    }
}
}
