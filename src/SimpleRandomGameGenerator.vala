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
public class SimpleRandomGameGenerator : AbstractGameGenerator {

    public SimpleRandomGameGenerator (Dimensions _dimensions, Cancellable? _cancellable) {
        pattern_gen = new RandomPatternGenerator (_dimensions);
        solver = new Solver (_dimensions, _cancellable);
    }

    public override bool generate () {
        /* returns true if a game of correct grade was generated otherwise false  */
        int passes = -1;
        uint count = 0;

        while (solution_grade != grade && !cancelled) {
            var pattern = pattern_gen.generate ();
            var row_clues = Utils.row_clues_from_2D_array (pattern);
            var col_clues = Utils.col_clues_from_2D_array (pattern);

            passes = solver.solve_clues (row_clues, col_clues, null, null);
            solution_grade = Utils.passes_to_grade (passes, dimensions, true, true);

            if (passes <= 0 || solution_grade > grade + 1) {
                if (++count > 200 ) {
                    count = 0;
                    pattern_gen.easier ();
                }
            } else {
                if (solution_grade < grade) {
                    count = 0;
                    pattern_gen.harder ();
                }
            }
        }

        var result = solution_grade == grade && !cancelled;

        return result;
    }

    public override My2DCellArray get_solution () {
        var solution = new My2DCellArray (dimensions);
        solution.copy (solver.solution);
        return solution;
    }
}
}
