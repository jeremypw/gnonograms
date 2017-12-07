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
public class SimpleGenerator : AbstractGenerator {

    int threshold = 4;

    public SimpleGenerator (Dimensions dim, Difficulty grade) {
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
                    threshold = 1;
                    break;
            case Difficulty.VERY_EASY:
                    threshold = 2;
                    break;
            case Difficulty.EASY:
                    threshold = 3;
                    break;
            case Difficulty.MODERATE:
                    threshold = 4;
                    break;
            case Difficulty.HARD:
                    threshold = 5;
                    break;
            case Difficulty.CHALLENGING:
                    threshold = 6;
                    break;
            case Difficulty.ADVANCED:
                    threshold = 7;
                    break;
            case Difficulty.MAXIMUM:
                    threshold = 8;
                    break;
            default:
                threshold = 4;
                break;
        }
    }

    private void new_pattern (ref My2DCellArray grid) {
        CellState cs = CellState.EMPTY;

        for (int r = 0; r < dimensions.rows (); r++) {
            for (int c = 0; c < dimensions.cols (); c++) {
                cs = rand_gen.int_range (0, 9) > threshold ? CellState.FILLED : CellState.EMPTY;
                grid.set_data_from_rc (r, c, cs);
            }
        }
    }
}
}
