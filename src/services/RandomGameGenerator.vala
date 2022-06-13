/* SimpleRandomGameGenerator.vala
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
public class Gnonograms.SimpleRandomGameGenerator : Object {
    public RandomPatternGenerator pattern_gen { get; construct; }
    public Solver solver { get; construct; }

    public Difficulty solution_grade { get; set; default = Difficulty.UNDEFINED; }

    public bool cancelled {
        get {
            return solver.cancelled;
        }
    }

    public Difficulty grade {
        set {
            pattern_gen.grade = value;
            solver.configure_from_grade (value);
        }
    }

    public SimpleRandomGameGenerator (Dimensions _dimensions, Solver _solver) {
        Object (
            pattern_gen: new RandomPatternGenerator (_dimensions),
            solver: _solver
        );
    }

    public async bool generate () {
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

            solution_grade = yield solver.solve_clues (row_clues, col_clues, null, null);

            if (solver.state.solved ()) {
                if (solution_grade == pattern_gen.grade) {
                    break;
                } else if (solution_grade > pattern_gen.grade) {
                    too_hard++;
                } else {
                    too_easy++;
                }
            } else {
                unsolved++;
            }

            count++;
            if (count < 1000) {
                continue;
            } else {
                if (unsolved > 950 || (too_hard > too_easy)) {
                    pattern_gen.easier ();
                } else if (too_easy > too_hard) {
                    pattern_gen.harder ();
                }

                count = 0;
                too_hard = 0;
                too_easy = 0;
                unsolved = 0;
            }
        }

        assert (solver.state != SolverState.ERROR);
        return !cancelled;
    }

    public My2DCellArray get_solution () {
        var solution = new My2DCellArray (pattern_gen.dimensions);
        solution.copy (solver.solution);
        return solution;
    }

    public void cancel () {
        solver.cancel ();
    }
}
