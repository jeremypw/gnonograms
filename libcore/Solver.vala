/* Solver.vala
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

 public class Gnonograms.Solver : Object {
    public SolverState state { get; set; }
    public My2DCellArray grid { get; protected set; } // Shared with Regions which can update the contents
    public My2DCellArray solution { get; protected set; }
    public Cancellable? cancellable { get; set; }
    public bool cancelled {
        get {
            return cancellable != null ? cancellable.is_cancelled () : false;
        }
    }

    private Dimensions _dimensions;
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            _dimensions = value;
            grid = new My2DCellArray (_dimensions);
            solution = new My2DCellArray (_dimensions);
            regions = new Region[n_regions];

            for (int i = 0; i < n_regions; i++) {
                regions[i] = new Region (grid);
            }
        }
    }

    public bool unique_only { get; set; default = true;} /* Do not allow ambiguus solutions */
    public bool use_advanced { get; set; default = false;} /* Use advanced logic (trial and error) */
    public bool advanced_only { get; set; default = false;} /* Must need advanced logic */
    public bool human_only { get; set; default = true;} /* Limit solutions to those humanly achievable */
    public uint rows { get { return dimensions.height; }}
    public uint cols { get { return dimensions.width; }}

    private const double MODERATE_CPP = 5.0f;
    private const double HARD_CPP = 3.0f;
    private const double CHALLENGING_CPP = 1.5f;
    private const uint MAX_PASSES = 200;

    private Region[] regions;
    private uint n_regions { get { return dimensions.length (); }}
    private bool should_check_solution;
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

    /** Set up solver for a particular puzzle. In addition to the clues, a starting point
      * and/or the correct solution may be provided (useful for debugging).
    **/
    private bool initialize (string[] row_clues,
                             string[] col_clues,
                             My2DCellArray? start_grid = null,
                             My2DCellArray? solution_grid = null) {

        assert (row_clues.length == rows && col_clues.length == cols);
        should_check_solution = solution_grid != null;

        if (should_check_solution) {
            solution.copy (solution_grid);
        }

        if (start_grid != null) {
            grid.copy (start_grid);
        } else {
            grid.set_all (CellState.UNKNOWN);
        }

        int index = 0;
        for (int r = 0; r < rows; r++) {
            regions[index++].initialize (r, false, cols, row_clues[r]);
        }

        for (int c = 0; c < cols; c++) {
            regions[index++].initialize (c, true, rows, col_clues[c]);
        }

        state = SolverState.UNDEFINED;

        return valid ();
    }

    /** Initiate solving, specifying whether or not to use the advanced
      * procedures. Also specify whether in debugging mode and whether to solve one step
      * at a time (used for hinting if implemented).
    **/
    public async Difficulty solve_clues (string[] row_clues,
                                         string[] col_clues,
                                         My2DCellArray? start_grid = null,
                                         My2DCellArray? solution_grid = null) {

        if (initialize (row_clues, col_clues, start_grid, solution_grid)) {
            return yield solve_it ();
        } else {
            state = SolverState.ERROR;
            return Difficulty.UNDEFINED;
        }
    }

    public void cancel () {
        cancellable.cancel ();
    }

    private void reinitialize_regions () {
        int index = 0;
        for (int r = 0; r < rows; r++) {
            regions[index++].set_to_initial_state ();
        }

        for (int c = 0; c < cols; c++) {
            regions[index++].set_to_initial_state ();
        }
    }

    private bool valid () {
        foreach (Region r in regions) {
            if (r.in_error) {
                return false;
            }
        }

        int row_total = 0;
        int col_total = 0;
        for (int r = 0; r < rows; r++) {
            row_total += regions[r].block_total;
        }

        for (int c = 0; c < cols; c++) {
            col_total += regions[rows + c].block_total;
        }

        return row_total == col_total;
    }

    public bool solved () {
        foreach (Region r in regions) {
            if (!r.is_completed) {
                return false;
            }
        }

        return true;
    }

    public void configure_from_grade (Difficulty grade) {
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

    private async Difficulty solve_it () {
        int result = -1;
        for (int i = 0; i < n_regions; i++) {
            regions[i].set_to_initial_state ();
        }

        result = yield simple_solver ();
        if (state == SolverState.ERROR) {
            return Difficulty.UNDEFINED;
        } else {
            if (state == SolverState.SIMPLE && advanced_only) {
                result = 0;
            } else if (state != SolverState.SIMPLE && use_advanced) {
                result = yield advanced_solver (); // Sets state if solution found
            }
        }

        return passes_to_grade (result);
    }

#if WITH_DEBUGGING
    public Gee.ArrayQueue<Move> debug (uint idx, bool is_column, string[] row_clues,
                                       string[] col_clues, My2DCellArray working) {

        initialize (row_clues, col_clues, working, null);

        var moves = new Gee.ArrayQueue<Move> ();
        var r= regions[idx + (is_column ? rows : 0)];
        var changed = r.debug ();
        if (r.in_error) {
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
#endif

    public Gee.ArrayQueue<Move> hint (string[] row_clues, string[] col_clues, My2DCellArray working) {
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

        while (!changed && count < 2 &&
               state != SolverState.ERROR) { /* May require two passes before a state changes */

            changed = false;
            count++;
            foreach (Region r in regions) {
                if (r.is_completed) {
                    continue;
                }

                changed = r.solve ();
                if (r.in_error) {
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

    /** Returns -1 to indicate an error **/
    private async int simple_solver () {
        bool changed = true;
        int pass = 1;
        reinitialize_regions ();
        state = SolverState.NO_SOLUTION;
        Idle.add (() => {
            while (changed && pass >= 0 && pass < MAX_PASSES) {
                //keep cycling through regions while at least one of them is changing
                changed = false;
                foreach (Region r in regions) {
                    if (r.is_completed) {
                        continue;
                    }

                    changed |= r.solve ();
                    if (r.in_error) {
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

            simple_solver.callback ();
            return Source.REMOVE;
        });

        yield;

        solution.copy (grid);
        if (solved ()) {
            state = SolverState.SIMPLE;
        }

        return pass;
    }

    /** Make single cell guesses, depth 1 (no recursion)
        Make a guess in each unknown cell in turn
        If it leads to contradiction mark opposite to guess,
        continue simple solve and if still no solution, continue with another guess.
        If first guess does not lead to solution leave unknown and choose another cell
    **/
    private async int advanced_solver () {
        /* Simple solver must have already been run */
        var guesser = new Guesser (grid, human_only);
        var initial_state = SolverState.UNDEFINED;
        var inverse_state = SolverState.UNDEFINED;
        int result = 0;
        int min_to_contradiction = human_only ? 5 : (int)MAX_PASSES; // Humans cannot 'see' deep contradictions
        int contra = 0;
        int empty = 0;
        int min_empty_cells = int.MAX;
        int changed_count = 0;
        Cell best_guess = NULL_CELL;
        state = SolverState.UNDEFINED;

        while (state == SolverState.UNDEFINED) {
            changed_count++;

            if (!guesser.next_guess ()) {
                state = SolverState.NO_SOLUTION;
                if (best_guess.equal (NULL_CELL)) { // No improvement from last round
                    break;
                } else {
                    grid.set_data_from_cell (best_guess);
                    guesser = new Guesser (grid, false);
                    best_guess = NULL_CELL;
                    changed_count = 0;
                    if (!guesser.next_guess ()) {
                        warning ("No next guess");
                        break;
                    }
                }
            }

            result = yield simple_solver ();
            initial_state = state;

            if (initial_state == SolverState.NO_SOLUTION) {
                empty = solution.count_state (CellState.EMPTY);
                if (empty < min_empty_cells){
                    min_empty_cells = empty;
                    best_guess = guesser.get_trial_cell_copy ();
                }
            }

            /* Reject too difficult solution path */
            if (state == SolverState.ERROR && result > min_to_contradiction) {
                state = SolverState.UNDEFINED;
                guesser.cancel_previous_guess ();
                continue;
            }

            contra = result;

            /* Try opposite to check whether ambiguous or unique */
            guesser.invert_previous_guess ();
            result = yield simple_solver ();
            inverse_state = state;
            if (inverse_state == SolverState.NO_SOLUTION) {
                empty = grid.count_state (CellState.EMPTY);
                if (empty < min_empty_cells){
                    min_empty_cells = empty;
                    best_guess = guesser.get_trial_cell_copy ();
                }
            }

            if (initial_state == SolverState.ERROR && inverse_state == SolverState.ERROR) {
                state = SolverState.NO_SOLUTION;
                /* This can happen when generating advanced logic puzzles */
                break;
            }

            switch (inverse_state) {
                case SolverState.ERROR:
                    if (result > min_to_contradiction) {
                        guesser.cancel_previous_guess (); //
                        state = SolverState.UNDEFINED; // Continue (may be easier contradiction later)
                        break;
                    }

                    contra = result;
                    /* Regenerate original result */
                    guesser.invert_previous_guess ();
                    result = yield simple_solver ();

                    if (initial_state == SolverState.SIMPLE) {
                        state = SolverState.ADVANCED;
                    } else if (initial_state == SolverState.NO_SOLUTION) { // original cannot be in error
                        /* continue from original result here */
                        guesser.initialize ();
                        state = SolverState.UNDEFINED;
                    } else {
                        critical ("unexpected initial tate %s", initial_state.to_string ());
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
                            result = yield simple_solver ();
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
        private uint initial_max_turns = 3;
        private CellState initial_cell_state = CellState.EMPTY;
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

            trial_cell = { 0, -1, initial_cell_state };
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

        public Cell get_trial_cell_copy () {
            return trial_cell.clone ();
        }
    }
}
