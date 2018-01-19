/* Handles working and solution data for gnonograms
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
        uint count = 0;

        while (!cancelled) {
            var pattern = pattern_gen.generate ();
            var row_clues = Utils.row_clues_from_2D_array (pattern);
            var col_clues = Utils.col_clues_from_2D_array (pattern);

            solution_grade = solver.solve_clues (row_clues, col_clues, null, null);

            if (solver.state.solved ()) {
                if (solution_grade == grade) {
                    break;
                } else {
                    count++;
                    if (count < 20) {
                        continue;
                    } else {
                        count = 0;
                        if (solution_grade > grade) {
                            pattern_gen.easier ();
                        } else {
                            pattern_gen.harder ();
                        }
                    }
                }
            }
        }

        assert (solver.state != SolverState.ERROR);
        return !cancelled;
    }

    public override My2DCellArray get_solution () {
        var solution = new My2DCellArray (dimensions);
        solution.copy (solver.solution);
        return solution;
    }
}
}
