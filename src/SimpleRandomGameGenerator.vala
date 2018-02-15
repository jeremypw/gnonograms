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
        uint unsolved = 0;
        uint total_tries = 0;
        uint too_hard = 0;
        uint too_easy = 0;

        while (!cancelled) {
            total_tries++;
            var pattern = pattern_gen.generate ();
            var row_clues = Utils.row_clues_from_2D_array (pattern);
            var col_clues = Utils.col_clues_from_2D_array (pattern);

            solution_grade = solver.solve_clues (row_clues, col_clues, null, null);

            if (solver.state.solved ()) {
                if (solution_grade == grade) {
                    break;
                }

                if (solution_grade > grade) {
                    too_hard++;
                } else {
                    too_easy++;
                }
            } else {
                unsolved++;
            }

            count++;

            if (count < 100) {
                continue;
            } else {
                if (too_hard > too_easy) {
                    pattern_gen.easier ();
                } else if (too_easy > too_hard) {
                    pattern_gen.harder ();
                }
                count = 0;
                too_hard = 0;
                too_easy = 0;
            }
        }

        assert (solver.state != SolverState.ERROR);
        debug ("total tries %u, unsolved %u, too_hard %u, too_easy %u", total_tries, unsolved, too_hard, too_easy);
        RandomPatternGenerator pg = pattern_gen as RandomPatternGenerator;
        debug ("threshold %u, min free %u, edge %u", pg.threshold, pg.min_freedom, pg.edge_bias);
        return !cancelled;
    }

    public override My2DCellArray get_solution () {
        var solution = new My2DCellArray (dimensions);
        solution.copy (solver.solution);
        return solution;
    }
}
}
