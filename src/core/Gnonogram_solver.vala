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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {
 public class Solver : GLib.Object {
    /** PUBLIC **/

    public My2DCellArray grid {get; private set;}
    public My2DCellArray solution {get; private set;}

    public Dimensions dimensions {
        set {
            rows = value.height;
            cols = value.width;
            n_regions = rows + cols;

            grid = new My2DCellArray (value);
            solution = new My2DCellArray (value);
            regions = new Region[n_regions];

            for (int i = 0; i < n_regions; i++) {
                regions[i] = new Region (grid);
            }
        }
    }

    /** Set up solver for a particular puzzle. In addition to the clues, a starting point
      * and/or the correct solution may be provided (useful for debugging).
    **/
    public bool initialize (string[] row_clues,
                            string[] col_clues,
                            My2DCellArray? start_grid = null,
                            My2DCellArray? solution_grid = null) {

        assert (row_clues.length == rows && col_clues.length == cols);

        should_check_solution = false;

        if (solution_grid != null) {
            should_check_solution = true;
            solution.copy (solution_grid);
        }

        if (start_grid != null) {
            grid.copy (start_grid);
        } else {
            grid.set_all (CellState.UNKNOWN);
        }

        for (int r = 0; r < rows; r++) {
            regions[r].initialize (r, false, cols, row_clues[r]);
        }

        for (int c = 0; c < cols; c++) {
            regions[c + rows].initialize (c, true, rows, col_clues[c]);
        }

        return valid ();
    }

    public bool valid () {
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

    /** Initiate solving, specifying whether or not to use the advanced and ultimate
      * procedures. Also specify whether in debugging mode and whether to solve one step
      * at a time (used for hinting if implemented).
    **/
    public async uint solve_it (bool debug = false,
                                bool use_advanced = true,
                                bool use_ultimate = true,
                                bool unique_only = false,
                                bool stepwise = false) {
        guesses = 0;

        uint result = yield simple_solver (debug,
                                           should_check_solution,
                                           stepwise);

        if (result == 0 && use_advanced) {
            CellState[] grid_backup =  new CellState[rows * cols];

            result = yield advanced_solver (grid_backup,
                                            use_ultimate,
                                            debug,
                                            9999,
                                            unique_only);

            if (result == 0 && use_ultimate) {
                result = yield ultimate_solver (grid_backup);
            }
        }

        if (rows == 1) {
            stdout.printf (regions[0].to_string ());  //used for debugging
        }

        return result;
    }

    public bool solved () {
        foreach (Region r in regions) {
            if (!r.is_completed) {
                return false;
            }
        }

        return true;
    }

    /** PRIVATE **/
    private uint rows;
    private uint cols;
    private Region[] regions;
    private uint n_regions;

    private Cell trial_cell;
    private int rdir;
    private int cdir;
    private int rlim;
    private int clim;
    private int turn;
    private uint max_turns;
    private uint guesses = 0;

    private bool should_check_solution;

    static uint MAX_PASSES = 1000;

    /** Returns -1 to indicate an error - TODO use throw error instead **/
    private async int simple_solver (bool debug,
                                      bool should_check_solution,
                                      bool stepwise) {

        int result = 0;

        Idle.add (() => {
            result = do_simple_solve (debug, should_check_solution, stepwise);
            simple_solver.callback ();
            return false;
        });

        yield;
        return result;
    }

    private int do_simple_solve (bool debug,
                                  bool should_check_solution,
                                  bool stepwise) {
        bool changed = true;
        int pass = 1;

        while (changed && pass < MAX_PASSES) {
            //keep cycling through regions while at least one of them is changing
            changed = false;

            foreach (Region r in regions) {
                if (r.is_completed) {
                    continue;
                }

                if (r.solve (debug, false)) {
                    changed = true; //no hinting
                }

                if (r.in_error) {
                    if (debug) {
                        stdout.printf ("::" + r.message);
                        stdout.printf (r.to_string ());
                    }

                    return  -1;
                }

                if (should_check_solution && differs_from_solution (r)) {
                    stdout.printf (r.to_string ());
                    return  -1;
                }

                if (debug) {
                    stdout.printf (r.to_string ());
                }
            }

            if (stepwise) {
                break;
            }

            pass++;
        }

        if (solved ()) {
            solution.copy (grid);
            return pass;
        }

        if (pass >= MAX_PASSES) {
            return Gnonograms.FAILED_PASSES;
        }

        return 0;
    }

    private bool differs_from_solution (Region r) {
        bool is_column = r.is_column;
        uint index = r.index;
        int n_cells = r.n_cells;
        int solution_state;
        int region_state;

        for (uint i = 0; i < n_cells; i++) {
            region_state = r.get_cell_state (i);

            if (region_state == CellState.UNKNOWN) {
                continue;
            }

            solution_state = solution.get_data_from_rc (is_column ? i : index,
                                                        is_column ? index : i);

            if (solution_state == CellState.EMPTY) {
                if (region_state == CellState.EMPTY) {
                    continue;
                }
            } else { //solution_state is FILLED
                if (region_state != CellState.EMPTY) {
                    continue;
                }
            }

            return true;
        }

        return false;
    }

    /** Make single cell guesses, depth 1 (no recursion)
        Make a guess in each unknown cell in turn
        If it leads to contradiction mark opposite to guess,
        continue simple solve and if still no solution, continue with another guess.
        If first guess does not lead to solution leave unknown and choose another cell
    **/
    private async int advanced_solver (CellState[] grid_backup,
                                       bool use_ultimate = true,
                                       bool debug = false,
                                       int max_guesswork = 999,
                                       bool unique_only = false) {
        int simple_result = 0;
        int wraps = 0;
        int guesses = 0;
        bool changed = false;
        int changed_count = 0;
        uint initial_max_turns = 3; //stay near edges until no more changes
        CellState initial_cell_state = CellState.FILLED;

        rdir = 0;
        cdir = 1;
        rlim = (int)rows;
        clim = (int)cols;

        turn = 0;
        max_turns = initial_max_turns;
        guesses = 0;

        trial_cell = { 0, uint.MAX, initial_cell_state };

        this.save_position (grid_backup);

        while (true) {
            trial_cell = make_guess (trial_cell);
            guesses++;

            if (trial_cell.col == uint.MAX) { //run out of guesses
                if (changed) {
                    if (changed_count > max_guesswork) {
                        return 0;
                    }
                } else if (max_turns == initial_max_turns) {
                    max_turns = (uint.min (rows, cols)) / 2 + 2; //ensure full coverage
                } else if (trial_cell.state == initial_cell_state) {
                    trial_cell = trial_cell.invert (); //start making opposite guesses
                    max_turns = initial_max_turns;
                    wraps = 0;
                } else {
                    break; //cannot make progress
                }

                rdir = 0;
                cdir = 1;
                rlim = (int)rows;
                clim = (int)cols;
                turn = 0;

                changed = false;

                wraps++;
                continue;
            }

            grid.set_data_from_cell (trial_cell);

            simple_result = yield simple_solver (false, // not debug
                                                 false, // do not check solution
                                                 false); // not stepwise

            if (simple_result > 0) {

                if (unique_only) { //unique solutions must be solved by contradiction.
                    changed_count++;
                    simple_result = 0;
                }

                break;
            }

            load_position (grid_backup); //back track

            if (simple_result < 0) { //contradiction  -   insert opposite guess
                grid.set_data_from_cell (trial_cell.invert ()); //mark opposite to guess
                changed = true;
                changed_count++; //worth trying another cycle

                simple_result = yield simple_solver (false, // not debug
                                                     false, // do not check solution
                                                     false); // not stepwise

                if (simple_result == 0) { //no we cant
                    this.save_position (grid_backup); //update grid store
                    continue; //go back to start
                } else if (simple_result > 0) {
                    break; // unique solution found
                } else {
                    return -1; //starting point was invalid - cannot contradict both options.
                }
            }
        }

        //return vague measure of difficulty
        if (simple_result > 0 && simple_result < Gnonograms.FAILED_PASSES) {
            return simple_result + changed_count * 20;
        }

        return 0;
    }

    /** Store the grid in linearised form **/
    private void save_position (CellState[] gs) {
        for (int r = 0; r < rows; r++) {

            for (int c = 0; c < cols; c++) {
                gs[r * cols + c] = grid.get_data_from_rc (r, c);
            }
        }

        for (int i = 0; i < n_regions; i++) {
            regions[i].save_state ();
        }
    }

    private void load_position (CellState[] gs) {
        for (int r = 0; r < rows; r++) {

            for (int c = 0; c < cols; c++) {
                grid.set_data_from_rc (r, c, gs[r * cols + c]);
            }
        }

        for (int i = 0; i < n_regions; i++) {
            regions[i].restore_state ();
        }
    }

    /** Used by advanced solver. Scans in a spiral pattern from edges
      * as critical cells most likely in this region.
    **/
    private Cell make_guess (Cell cell) {
        int r = (int)(cell.row);
        int c = (int)(cell.col);

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
                cell.row = 0;
                cell.col = uint.MAX;
                break;
            }

            if (grid.get_data_from_rc (r, c) == CellState.UNKNOWN) {
                cell.row = (uint)r;
                cell.col = (uint)c;
                break;
            }
        }

        return cell;
    }

    /** The ultimate solver take a region and runs through all possible permutations
      * of filled and empty cells in that region, trying to solve the puzzle from that
      * point on using the advanced solver. If that fails, another region is chosen to permute.
      * Puzzles requiring this method are unlikely to solvable by a human and are unlikely to
      * have a unique solution so its utility is debatable.
    **/
    private async uint ultimate_solver(CellState[] grid_store) {
        load_position (grid_store); //return to last valid state
        return yield permute (grid_store);
    }

    private async uint permute (CellState[] grid_store) {
        uint permute_region;

        CellState[] grid_backup2 = new CellState[rows * cols];
        CellState[] guess = {};

        for (int i = 0; i < n_regions; i++) {
            regions[i].set_to_initial_state();
        }

        yield simple_solver (false, // not debug
                             false, // do not check solution
                             false); // not stepwise

        while (true) {
            permute_region = choose_permute_region ();

            if (permute_region == uint.MAX) {
                stdout.printf ("No more permute regions found\n");
                break;
            }

            var reg = regions[permute_region];
            reg.value_as_permute_region = 0; /* So will not be re-chosen */

            int start;

            var p = reg.get_permutor (out start);

            if (p == null || !p.valid) {
                continue;
            }

            bool is_column = regions[permute_region].is_column;
            uint idx = regions[permute_region].index;
            //try advanced solver with every possible pattern in this range.

            for (int i = 0; i < n_regions; i++) {
                regions[i].set_to_initial_state ();
            }

            save_position (grid_backup2);

            p.initialise ();

            while (p.next()) {
                guesses++;

                guess = p.permutation;

                grid.set_array (idx, is_column, guess, start);

                int simple_result = yield simple_solver (false, // not debug
                                                          false, // do not check solution
                                                          false); // not stepwise

                if (simple_result == 0) {
                    int advanced_result = yield advanced_solver (grid_store, false);

                    if (advanced_result > 0 && advanced_result < Gnonograms.FAILED_PASSES) {
                        return advanced_result; //solution found
                    }
                } else if (simple_result > 0) {
                    return simple_result + guesses; //unlikely!
                }

                load_position (grid_backup2); //back track

                for (int i = 0; i < n_regions; i++) {
                    regions[i].set_to_initial_state();
                }
            }

            load_position (grid_backup2); //back track

            for (int i = 0; i < n_regions; i++) {
                regions[i].set_to_initial_state();
            }

            yield simple_solver (false,
                                 false,
                                 false);
        }

        return 0;
    }

    /** Try to find a region of the puzzle most likely to yield a solution
      * (or contradiction) if permuted.
    **/
    private uint choose_permute_region () {
        uint best_value = 0;
        uint permute_region = uint.MAX;
        uint edg; /* A measure of how close to the edge the region is - modifies value. */
        uint current_value;

        for (uint r = 0; r < n_regions; r++) {
            current_value = regions[r].value_as_permute_region;

            if (current_value == 0) {
                continue;
            }

            if (r < rows) {
                edg = uint.min (r, rows - 1 - r);
            } else {
                edg = uint.min (r - rows, rows + cols - r - 1);
            }

            current_value = current_value / ++edg;

            if (current_value >= best_value) {
                best_value = current_value;
                permute_region = r;
            }
        }

        return permute_region;
    }
}
}
