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

    /* Cells solved per pass factors for different grades. The lower the factor, the more time consuming
     * it is to generate or solve a puzzle of that grade.
     */
    private const double MODERATE_CPP = 5.0f;
    private const double HARD_CPP = 3.0f;
    private const double CHALLENGING_CPP = 1.5f;

    /* Corresponding pass numbers for different grade (depends on dimensions) */
    private uint moderate_threshold;
    private uint hard_threshold;
    private uint challenging_threshold;

    public Solver (Dimensions _dimensions) {
        Object (
            dimensions: _dimensions
        );

        double length = (double)(dimensions.length ());

        moderate_threshold = (uint)((length / MODERATE_CPP + 0.5)); /* Round up */
        hard_threshold = (uint)((length / HARD_CPP + 0.5)); /* Round up */
        challenging_threshold = (uint)((length / CHALLENGING_CPP - 0.5)); /* Round down */
    }

    public override void configure_from_grade (Difficulty grade) {
        use_advanced = false;
        unique_only = true;
        advanced_only = false;
        human_only = true;

        switch (grade) {
            case Difficulty.EASY:
            case Difficulty.MODERATE:
            case Difficulty.HARD:
            case Difficulty.CHALLENGING:

                break;

            case Difficulty.ADVANCED:
                use_advanced = true;
                advanced_only = true;

                break;

            case Difficulty.MAXIMUM:
                use_advanced = true;
                unique_only = false;
                advanced_only = true;

                break;

            case Difficulty.COMPUTER:
                use_advanced = true;
                unique_only = false;
                advanced_only = false;
                human_only = false;

                break;
            default:
                assert_not_reached ();
        }
    }

    protected override Difficulty solve_it () {
        for (int i = 0; i < n_regions; i++) {
            regions[i].set_to_initial_state ();
        }

        int result = simple_solver ();

        if (state == SolverState.SIMPLE && advanced_only) {
            result = 0;
        } else if (state != SolverState.SIMPLE && use_advanced) {
            result = advanced_solver (); // Sets state if solution found
        }

        return passes_to_grade (result);
    }

    public override Gee.ArrayQueue<Move> debug (uint idx, bool is_column, string[] row_clues, string[] col_clues, My2DCellArray working) {
        var moves = new Gee.ArrayQueue<Move> ();
        initialize (row_clues, col_clues, working, null);
        var r= regions[idx + (is_column ? rows : 0)];
        var changed = r.debug ();

        if (r.in_error) {
            /* TODO Use conditional compilation to print out error if required */
            state = SolverState.ERROR;
            critical ("Debugged Region in error");
        }

        if (changed) {
            var size = r.is_column ? rows : cols;
            var csa = new CellState[size];
            working.get_array (r.index, r.is_column, ref csa);
            for (int i = 0; i < size; i++) {
                var r_state = r.get_cell_state (i);
                if (r_state != CellState.UNKNOWN && csa[i] != r_state) {
                    var row = r.is_column ? i : r.index;
                    var col = r.is_column ? r.index : i;
                    Cell c = {row, col, r_state};
                    moves.add (new Move (c, csa[i]));
                    break;
                }
            }
        }

        return moves;
    }

    public override Gee.ArrayQueue<Move> hint (string[] row_clues, string[] col_clues, My2DCellArray working) {
        assert (working.dimensions.equal (grid.dimensions));
        assert (working.dimensions.rows () == row_clues.length);
        assert (working.dimensions.cols () == col_clues.length);

        initialize (row_clues, col_clues, working, null);

        bool changed = false;
        uint count = 0;

        var moves = new Gee.ArrayQueue<Move> ();

        /* Initialize may have changed state of some cells during initial fix */
        foreach (Region r in regions) {
            var size = r.is_column ? rows : cols;
            var csa = new CellState[size];
            working.get_array (r.index, r.is_column, ref csa);
            for (int i = 0; i < size; i++) {
                var r_state = r.get_cell_state (i);

                if (r_state != CellState.UNKNOWN && csa[i] != r_state) {
                    var row = r.is_column ? i : r.index;
                    var col = r.is_column ? r.index : i;
                    Cell c = {row, col, r_state};
                    moves.add (new Move (c, csa[i]));
                    changed = true;
                }
            }
        }

        while (!changed && count < 2 && state != SolverState.ERROR) { /* May require two passes before a state changes */
            changed = false;
            count++;

            foreach (Region r in regions) {
                if (r.is_completed) {
                    continue;
                }

                changed = r.solve ();

                if (r.in_error) {
                    /* TODO Use conditional compilation to print out error if required */
                    state = SolverState.ERROR;
                    break;
                }

                if (changed) {
                    var size = r.is_column ? rows : cols;
                    var csa = new CellState[size];
                    working.get_array (r.index, r.is_column, ref csa);
                    for (int i = 0; i < size; i++) {
                        var r_state = r.get_cell_state (i);
                        if (r_state != CellState.UNKNOWN && csa[i] != r_state) {
                            var row = r.is_column ? i : r.index;
                            var col = r.is_column ? r.index : i;
                            Cell c = {row, col, r_state};
                            moves.add (new Move (c, csa[i]));
                            break;
                        }
                    }

                    break;
                }
            }
        }

        return moves;
    }

    /** PRIVATE **/

    /** Returns -1 to indicate an error - TODO use throw error instead **/
    private int simple_solver () {
        bool changed = true;
        int pass = 1;
        reinitialize_regions ();

        state = SolverState.UNDEFINED;

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
                    state = SolverState.ERROR;
                    break;
                }
            }

            pass++;

            if (cancellable.is_cancelled () ) {
                state = SolverState.CANCELLED;
                break;
            }
        }

        solution.copy (grid);

        if (!(state in (SolverState.ERROR | SolverState.CANCELLED))) {
            if (solved ()) {
                state = SolverState.SIMPLE;
            } else {
                state = SolverState.NO_SOLUTION;
                pass = 0; // not solved and not in error
            }
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
        int result = 0;
        int changed_count = 0;
        int min_to_contradiction = human_only ? 5 : (int)MAX_PASSES; // Humans cannot 'see' deep contradictions
        var guesser = new Guesser (grid, human_only);

        var initial_state = SolverState.UNDEFINED;
        var inverse_state = SolverState.UNDEFINED;
        int contra = 0;

        state = SolverState.UNDEFINED;
        while (state == SolverState.UNDEFINED) {
            changed_count++;

            if (!guesser.next_guess ()) {
                state = SolverState.NO_SOLUTION;
                break;
            }

            result = simple_solver ();
            initial_state = state;

            /* Reject too difficult solution path */
            if (state == SolverState.ERROR && result > min_to_contradiction) {
                state = SolverState.UNDEFINED;
                guesser.cancel_previous_guess ();
                continue;
            }

            contra = result;

            /* Try opposite to check whether ambiguous or unique */
            guesser.invert_previous_guess ();
            result = simple_solver () ;
            inverse_state = state;

            if (initial_state == SolverState.ERROR && inverse_state == SolverState.ERROR) {
                state = SolverState.NO_SOLUTION;
                /* This can happen when generating advanced logic puzzles */
                break;
            }

            switch (inverse_state) {
                case SolverState.ERROR:
                    if (initial_state == SolverState.ERROR || result > min_to_contradiction) {
                        guesser.cancel_previous_guess (); //
                        state = SolverState.UNDEFINED; // Continue (may be easier contradiction later)
                        break;
                    }

                    contra = result;
                    /* Regenerate original result */
                    guesser.invert_previous_guess ();
                    result = simple_solver ();

                    if (initial_state == SolverState.SIMPLE) {
                        state = SolverState.ADVANCED;
                    } else if (initial_state == SolverState.NO_SOLUTION) { // original cannot be in error
                        /* continue from original result here */
                        guesser.initialize ();
                        state = SolverState.UNDEFINED;
                    } else {
                        critical ("unexpected sinitial tate %s", initial_state.to_string ());
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
                            result = simple_solver ();
                            state = SolverState.AMBIGUOUS;
                        }
                    } else if (initial_state == SolverState.ERROR) { // already checked for too may passes to contradiction.
                        guesser.initialize ();
                        /* Continue from this position */
                        state = SolverState.UNDEFINED;
                    } else if (initial_state == SolverState.NO_SOLUTION) { // could be erroneous
                        // regenerate original position
                        guesser.cancel_previous_guess ();
                        state = SolverState.UNDEFINED;
                    } else {
                        critical ("unexpected initial state %s", initial_state.to_string ());
                        assert_not_reached ();
                    }

                    break;

                case SolverState.SIMPLE:
                    // INVERSE guess yielded a solution.
                    if (initial_state == SolverState.ERROR) {
                        state = SolverState.ADVANCED;
                    } else {
                        if (unique_only) {
                            state = SolverState.NO_SOLUTION;
                        } else {
                            state = SolverState.AMBIGUOUS;
                        }
                    }

                    break;

                case SolverState.CANCELLED:
                    break;

                default:
                    critical ("unexpected state %s", inverse_state.to_string ());
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
            case SolverState.AMBIGUOUS:
                return result;

            default:
                critical ("unexpected state %s", state.to_string ());
                assert_not_reached ();
        }
    }


    /** Only call if simple solver used **/
    private Difficulty passes_to_grade (uint passes) {
        Difficulty result;

        if (passes == 0) {
            result = Difficulty.UNDEFINED;
        } else if (state == SolverState.ADVANCED) {
            result = Difficulty.ADVANCED;
        } else if (state == SolverState.AMBIGUOUS) {
            result = Difficulty.MAXIMUM;
        } else if (passes >= challenging_threshold ) {
            result = Difficulty.CHALLENGING;
        } else if (passes >= hard_threshold) {
            result = Difficulty.HARD;
        } else if (passes >= moderate_threshold ) {
            result = Difficulty.MODERATE;
        } else {
            result = Difficulty.EASY;
        }

        return result;
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
        private bool human_only;

    /** Store the grid in linearised form **/
        private CellState[] gs;
        private My2DCellArray _grid;
        public My2DCellArray grid {
            get {
                return _grid;
            }

            private set {
                _grid = value;
                 gs = new CellState[_grid.area];
            }
        }

        public uint rows { get {return _grid.rows; }}
        public uint cols { get {return _grid.cols; }}

        public Guesser (My2DCellArray _grid, bool _human_only) {
            grid = _grid;
            rlim = (int)rows;
            clim = (int)cols;
            human_only = _human_only;
            initialize ();
        }

        public void initialize () {
            rdir = 0;
            cdir = 1;
            turn = 0;
            if (human_only) {
                max_turns = initial_max_turns;
            } else {
                max_turns = uint.min (rows, cols) / 2;
            }

            trial_cell = { 0, uint.MAX, initial_cell_state };
        }

        public bool next_guess () {
            save_position ();
            var guessed = make_guess ();
            return guessed;
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
