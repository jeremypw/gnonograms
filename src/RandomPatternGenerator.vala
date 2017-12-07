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
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms {
public class RandomPatternGenerator : AbstractPatternGenerator {

    int threshold = 40;
    int min_freedom = 0;

    public RandomPatternGenerator (Dimensions dim, Difficulty grade) {
        Object (dimensions: dim,
                grade: grade
        );
    }

    public override My2DCellArray generate () {
        var grid = new My2DCellArray (dimensions);

        new_pattern (ref grid);


        return grid;
    }

    public override void easier () {
        threshold--;
    }

    public override void harder () {
        threshold++;
    }

    protected override void set_parameters () {
        switch (grade) {
            case Difficulty.TRIVIAL:
                    threshold = 50;
                    min_freedom = 0;
                    break;
            case Difficulty.VERY_EASY:
                    threshold = 60;
                    min_freedom = 0;
                    break;
            case Difficulty.EASY:
                    threshold = 60;
                    min_freedom = 0;
                    break;
            case Difficulty.MODERATE:
                    threshold = 67;
                    min_freedom = 1;
                    break;
            case Difficulty.HARD:
                    threshold = 70;
                    min_freedom = 2;
                    break;
            case Difficulty.CHALLENGING:
                    threshold = 75;
                    min_freedom = 3;
                    break;
            case Difficulty.ADVANCED:
                    threshold = 70;
                    min_freedom = 3;
                    break;
            case Difficulty.MAXIMUM:
                    threshold = 70;
                    min_freedom = 4;
                    break;
            default:
                threshold = 40;
                break;
        }
    }

    private void new_pattern (ref My2DCellArray grid) {
        var total = rows * cols;
        CellState[] state = new CellState[total];

        int index = 0;
        while (index < total) {
            var cs = rand_gen.int_range (0, 99) > threshold ? CellState.FILLED : CellState.EMPTY;
            var length = rand_gen.int_range (1, 3);

            while (length > 0 && index < total) {
                state[index] = cs;
                index++;
                length--;
            }
        }

        index = 0;
        for (uint r = 0; r < rows; r++) {
            for (uint c = 0; c < cols; c++) {
                grid.set_data_from_rc (r, c, state[index]);
                index++;
            }
        }

        /* Make more even pattern */
        index = 0;
        while (index < total) {
            var cs = rand_gen.int_range (0, 99) > threshold ? CellState.FILLED : CellState.EMPTY;
            var length = rand_gen.int_range (1, 3);

            while (length > 0 && index < total) {
                state[index] = cs;
                index++;
                length--;
            }
        }

        index = 0;
        for (uint c = 0; c < cols; c++) {
            for (uint r = 0; r < rows; r++) {
                var cs = state[index];
                if (cs == CellState.FILLED) {
                    grid.set_data_from_rc (r, c, cs);
                }

                index++;
            }
        }

        /* Adjust freedom of each row and col if necessary */
        if (rows >= 10 && min_freedom > 0) {
            CellState[] sa = new CellState[rows];
            int df, filled, blocks;

            for (uint r = 0; r < rows; r++) {
                grid.get_array (r, false, ref sa);
                df = Utils.freedom_from_array (sa, out filled, out blocks);
                /* Insert random empty cells until enough freedom */
                while (df < min_freedom) {
                    var ptr = rand_gen.int_range (0, (int)cols);
                    if (sa[ptr] == CellState.FILLED) {
                        sa[ptr] = CellState.EMPTY;
                        df++;
                    }
                }
            }
        }
        if (cols >= 10 && min_freedom > 0) {
            CellState[] sa = new CellState[cols];
            int df, filled, blocks;

            for (uint c = 0; c < cols; c++) {
                grid.get_array (c, true, ref sa);
                df = Utils.freedom_from_array (sa, out filled, out blocks);
                /* Insert random empty cells until enough freedom */
                while (df < min_freedom) {
                    var ptr = rand_gen.int_range (0, (int)rows);
                    if (sa[ptr] == CellState.FILLED) {
                        sa[ptr] = CellState.EMPTY;
                        df++;
                    }
                }
            }
        }

    }
}
}
