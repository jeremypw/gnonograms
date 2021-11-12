/* RandomPatternGenerator.vala 
 * Copyright (C) 2010-2021  Jeremy Wootten
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
 *  Author: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.RandomPatternGenerator : Object {
    public Dimensions dimensions { get; construct; }

    private Difficulty _grade = Difficulty.EASY;
    public Difficulty grade {
        get {
            return _grade;
        }

        set {
            _grade = value;
            set_parameters ();
        }
    }

    public int threshold { get; set; default = 40;}
    public int min_freedom { get; set; default = 0;}
    public int edge_bias { get; set; default = 0;} /* Extra freedom for edge ranges */
    private int rows = 0;
    private int cols = 0;

    private Rand rand_gen;

    public RandomPatternGenerator (Dimensions dim) {
        Object (
            dimensions: dim
        );

        rows = (int)dim.height;
        cols = (int)dim.width;
        set_parameters ();
    }

    construct {
        rand_gen = new Rand ();
    }

    public My2DCellArray generate () {
        var grid = new My2DCellArray (dimensions, CellState.EMPTY);
        new_pattern (grid);

        return grid;
    }

    public void easier () {
        if (min_freedom > 1) {
            min_freedom--;
        } else if (threshold > 50) {
            threshold -= 2;
        }
    }

    public void harder () {}

    /* Approximately suitable parameters to generate puzzles of the required grade.
     * These factors do not affect the difficulty of the puzzles but may impact on the
     * length of time to generate a pattern with the correct grade.
     */
    protected void set_parameters () {
        edge_bias = 0;

        switch (grade) {
            case Difficulty.EASY:
                    threshold = 60;
                    min_freedom = 1;
                    break;
            case Difficulty.MODERATE:
                    threshold = 67;
                    min_freedom = 2;
                    break;
            case Difficulty.HARD:
                    threshold = 70;
                    min_freedom = 2;
                    edge_bias = 1;
                    break;
            case Difficulty.CHALLENGING:
                    threshold = 75;
                    min_freedom = 2;
                    edge_bias = 3;
                    break;
            case Difficulty.ADVANCED:
                    threshold = 65;
                    min_freedom = 4;
                    edge_bias = 0;
                    break;
            case Difficulty.MAXIMUM:
                    threshold = 70;
                    min_freedom = 4;
                    break;
            case Difficulty.UNDEFINED:
                    /* May not be defined on creation */
                    break;
            default:
                critical ("unexpected grade %s", grade.to_string ());
                assert_not_reached ();
        }
    }

    private void new_pattern (My2DCellArray grid) {
        var total = rows * cols;
        CellState[] state = new CellState[total];

        insert_random (state, false, grid); /* Insert random row patterns */
        insert_random (state, true, grid); /* Overlay with random column patterns */

        /* Adjust freedom of each row and col if necessary */
        if (min_freedom > 0) {
            adjust_region (false, grid);
            adjust_region (true, grid);
        }

        avoid_empty_regions (false, grid);
        avoid_empty_regions (true, grid);
    }

    private void insert_random (CellState[] sa, bool column_wise, My2DCellArray grid) {
        int total = sa.length;
        int index = 0;

        /* Create linear array of random filled and empty blocks */
        while (index < total) {
            var cs = rand_gen.int_range (0, 99) > threshold ? CellState.FILLED : CellState.EMPTY;
            var length = rand_gen.int_range (1, 3);

            while (length > 0 && index < total) {
                sa[index] = cs;
                index++;
                length--;
            }
        }

        /* Copy into grid either row-wise or column-wise */
        index = 0;
        if (column_wise) {
            for (uint c = 0; c < cols; c++) {
                for (uint r = 0; r < rows; r++) {
                    var cs = sa[index];
                    if (cs == CellState.FILLED) {
                        grid.set_data_from_rc (r, c, cs);
                    }
                    index++;
                }
            }
        } else {
            for (uint r = 0; r < rows; r++) {
                for (uint c = 0; c < cols; c++) {
                    grid.set_data_from_rc (r, c, sa[index]);
                    index++;
                }
            }
        }
    }

    /** Tweak rows or columns to comply with desired minimum degrees of freedom
      * The edges are made more sparse for more difficult puzzles.
      **/
    private void adjust_region (bool is_column, My2DCellArray grid) {
        uint lim = is_column ? cols : rows;
        uint size = is_column ? rows : cols;
        CellState[] sa = new CellState[size];
        int df, min;

        for (uint i = 0; i < lim; i++) {
            grid.get_array (i, is_column, ref sa);

            df = Utils.freedom_from_array (sa);
            if (df == size) {
                /* Do not want completely empty region */
                insert_filled (sa);
                continue;
            }

            /* Do not want to produce totally empty regions */
            min = int.min ((int)size - 1, min_freedom + (i < 2 || i > lim - 3 ? edge_bias : 0));

            if (df >= min) {
                continue;
            }

            insert_empty (min - df, sa);
            grid.set_array (i, is_column, sa);
        }
    }

    private void avoid_empty_regions (bool is_column, My2DCellArray grid) {
        uint lim = is_column ? cols : rows;
        uint size = is_column ? rows : cols;
        CellState[] sa = new CellState[size];
        int df;

        for (uint i = 0; i < lim; i++) {
            grid.get_array (i, is_column, ref sa);

            df = Utils.freedom_from_array (sa);
            if (df >= size) {
                insert_filled (sa);
                grid.set_array (i, is_column, sa);
                continue;
            }
        }
    }

    /** Randomly replace @replace filled cells with empty cells to increase degrees of freedom.
      * Work in from the ends so corners sparser.
     **/
    private void insert_empty (uint replace, CellState[] sa) {
        uint count = 0;
        uint lim = sa.length - 2;

        for (uint i = 1; i <= lim / 2 + 1; i++) {
            var ptr = i;
            if (sa[ptr] == CellState.FILLED) {
                sa[ptr] = CellState.EMPTY;
                if (++count == replace) {
                    break;
                }
            }

            ptr = lim - ptr;
            if (sa[ptr] == CellState.FILLED) {
                sa[ptr] = CellState.EMPTY;
                if (++count == replace) {
                    break;
                }
            }
        }
    }

    /** Only call for empty row/col **/
    private void insert_filled (CellState[] sa) {
        int lim = sa.length - 2;

        var ptr = rand_gen.int_range (1, lim);
        sa[ptr] = CellState.FILLED;
    }
}
