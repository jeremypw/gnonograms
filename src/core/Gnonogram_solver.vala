/* Solver class for gnonograms
 * Finds solution for a set of clues.
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
 public class Solver : AbstractSolver {
    /** Initiate solving, specifying whether or not to use the advanced
      * procedures. Also specify whether in debugging mode and whether to solve one step
      * at a time (used for hinting if implemented).
    **/

    public Solver (Dimensions _dimensions, Cancellable? _cancellable) {
        Object (dimensions: _dimensions,
                cancellable: _cancellable
        );
    }

    protected override int solve_it () {
        for (int i = 0; i < n_regions; i++) {
            regions[i].set_to_initial_state ();
        }

        int result = simple_solver ();

        if (state == SolverState.SIMPLE) {
            if (advanced_only) { // Do not want simple solutions
                return 0;
            }
        }

        if (state == SolverState.NO_SOLUTION && use_advanced) {
            result = advanced_solver (); // Sets state if solution found
        }

        return result;
    }

    /** PRIVATE **/

    /** Returns -1 to indicate an error - TODO use throw error instead **/
    private int simple_solver () {
        bool changed = true;
        int pass = 1;

        while (changed && pass >= 0 && pass < MAX_PASSES) {
            //keep cycling through regions while at least one of them is changing
            changed = false;

            foreach (Region r in regions) {
                if (r.is_completed) {
                    continue;
                }

                changed |= r.solve ();

                if (r.in_error) {
                    /* TODO Use conditional compilation to print out error if required */
                    pass = -2; // So still negative after increment
                    state = SolverState.ERROR;
                    break;
                }
            }

            pass++;

            if (cancellable.is_cancelled () ) {
                state = SolverState.CANCELLED;
                pass = -1;
                break;
            }
        }

        solution.copy (grid);

        if (solved ()) {
            state = SolverState.SIMPLE;
        } else  if (pass >= 0) {
            state = SolverState.NO_SOLUTION;
            pass = 0; // not solved and not in error
        }

        return pass;
    }

    /** Make single cell guesses, depth 1 (no recursion)
        Make a guess in each unknown cell in turn
        If it leads to contradiction mark opposite to guess,
        continue simple solve and if still no solution, continue with another guess.
        If first guess does not lead to solution leave unknown and choose another cell
    **/
    private int advanced_solver () {
        /* Simple solver must have already been run */
        int changed_count = 0;
        int result = 0;

        var guesser = new Guesser (grid);
        state = SolverState.UNDEFINED;

        while (state == SolverState.UNDEFINED)  {
            if (!guesser.next_guess ()) {
                break;
            }

            changed_count++;
            result = simple_solver ();
            var initial_state = state;

            /* Try opposite to check whether ambiguous or unique */
            guesser.invert_previous_guess ();
            reinitialize_regions ();
            result = simple_solver () ;
            var inverse_state = state;

            switch (inverse_state) {
                case SolverState.ERROR:
                    /* Regenerate original result */
                    guesser.invert_previous_guess ();
                    reinitialize_regions ();
                    result = simple_solver ();

                    if (initial_state == SolverState.ERROR) {
                        critical ("error both ways");
                    } else if (initial_state == SolverState.SIMPLE) {
                        // regenerate original solution
                        state = SolverState.ADVANCED;
                    } else if (initial_state == SolverState.NO_SOLUTION) { // original cannot be in error
                        /* continue from here */
                        state = SolverState.UNDEFINED;
                    } else {
                        assert_not_reached ();
                    }

                    break;

                case SolverState.NO_SOLUTION:
                    if (initial_state == SolverState.SIMPLE) {
                        if (unique_only) { /* reject ambiguous solution */
                            state = SolverState.NO_SOLUTION;
                        } else {
                            // regenerate original solution
                            guesser.invert_previous_guess ();
                            reinitialize_regions ();
                            result = simple_solver ();
                            state = SolverState.AMBIGUOUS;
                        }
                    } else if (initial_state == SolverState.ERROR) {
                        /* Continue from this position */
                        state = SolverState.UNDEFINED;
                    } else if (initial_state == SolverState.NO_SOLUTION) { // could be erroneous
                        // regenerate original position
                        guesser.cancel_previous_guess ();
                        reinitialize_regions ();
                        state = SolverState.UNDEFINED;
                    } else {
                        assert_not_reached ();
                    }

                    break;

                case SolverState.SIMPLE:
                    // INVERSE guess yielded a solution.
                    state = SolverState.ADVANCED;

                    if (initial_state == SolverState.NO_SOLUTION) {
                        if (unique_only) {
                            state = SolverState.NO_SOLUTION;
                        } else {
                            state = SolverState.AMBIGUOUS;
                        }
                    }

                    break;

                default:
                    assert_not_reached ();
            }

            if (cancellable.is_cancelled ()) {
                state = SolverState.CANCELLED;
                break;
            }
        }

        //return vague measure of difficulty
        switch (state) {
            case SolverState.CANCELLED:
            case SolverState.NO_SOLUTION:
                return 0;

            case SolverState.ADVANCED:
                return result + changed_count * 2;

            case SolverState.AMBIGUOUS:
                return result + changed_count * 10;

            case SolverState.UNDEFINED:
                state = SolverState.NO_SOLUTION;
                return 0;

            default:
                assert_not_reached ();
        }
    }

    private class Guesser {
        private Cell trial_cell;
        private int rdir;
        private int cdir;
        private int rlim;
        private int clim;
        private int turn;
        private uint max_turns;
        private const uint initial_max_turns = 3;
        private CellState initial_cell_state = CellState.EMPTY;
        private const uint max_guesswork = 9999;

    /** Store the grid in linearised form **/
        private CellState[] gs;
        private  My2DCellArray _grid;
        public  My2DCellArray grid {
            get {
                return _grid;
            }

            private set {
                _grid = value;
                 gs = new CellState[_grid.dimensions.area ()];
            }
        }

        public uint rows { get {return _grid.dimensions.rows (); }}
        public uint cols { get {return _grid.dimensions.cols (); }}

        public Guesser (My2DCellArray _grid) {
            grid = _grid;

            rdir = 0;
            cdir = 1;
            rlim = (int)rows;
            clim = (int)cols;
            turn = 0;
            max_turns = uint.min (rows, cols) / 2;
            trial_cell = { 0, uint.MAX, initial_cell_state };
        }

        public bool next_guess () {
            save_position ();
            return make_guess ();
        }

        public void invert_previous_guess () {
            load_position ();
            trial_cell = trial_cell.inverse ();
            grid.set_data_from_cell (trial_cell);
        }

        public void cancel_previous_guess () {
            load_position ();
            trial_cell = trial_cell.inverse ();
            grid.set_data_from_rc (trial_cell.row, trial_cell.col, CellState.UNKNOWN);
        }

        private void save_position () {
            int index = 0;
            for (int r = 0; r < rows; r++) {
                for (int c = 0; c < cols; c++) {
                    gs[index++] = grid.get_data_from_rc (r, c);
                }
            }
        }

        private void load_position () {
            int index = 0;
            for (int r = 0; r < rows; r++) {
                for (int c = 0; c < cols; c++) {
                    grid.set_data_from_rc (r, c, gs[index++]);
                }
            }
        }

        /** Used by advanced solver. Scans in a spiral pattern from edges
          * as critical cells most likely in this region.
        **/
        private bool make_guess () {
            int r = (int)(trial_cell.row);
            int c = (int)(trial_cell.col);

            while (true) {
                r += rdir;
                c += cdir; //only one changes at any one time

                if (cdir == 1 && c >= clim) {
                    c--;
                    cdir = 0;
                    rdir = 1;
                    r++;
                } else if (rdir == 1 && r >= rlim) { //across top  -  rh edge reached
                    r--;
                    rdir = 0;
                    cdir = -1;
                    c--;
                } else if (cdir == -1 && c < turn) { //down rh side  -  bottom reached
                    c++;
                    cdir = 0;
                    rdir = -1;
                     r--;
                } else if (rdir == -1 && r <= turn) { //back across bottom lh edge reached
                    r++;
                    turn++;
                    rlim--;
                    clim--;
                    rdir = 0;
                    cdir = 1;
                } //up lh side  -  top edge reached

                if (turn > max_turns) { //stay near edge until no more changes
                    trial_cell.row = 0;
                    trial_cell.col = uint.MAX;
                    return false;
                }

                if (grid.get_data_from_rc (r, c) == CellState.UNKNOWN) {
                    trial_cell.row = (uint)r;
                    trial_cell.col = (uint)c;
                    grid.set_data_from_cell (trial_cell);
                    break;
                }
            }

            return true;
        }

    }
}
}
