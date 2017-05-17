/* Solver class for Gnonograms - java
 * Finds solution for a set of clues
 * Contains extra code for advanced solving and hinting not used in this Java version
 * Copyright (C) 2012  Jeremy Wootten
 *
  This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110 - 1301 USA.
 *
 *  Author:
 *  Jeremy Wootten  < jeremwootten@gmail.com>
 */

namespace Gnonograms {

 public class Solver {
    public My2DCellArray grid;
    public My2DCellArray solution;

    private int rows;
    private int cols;
    private int regionCount;
    private Region[] regions;
    private Cell trialCell;
    private int rdir;
    private int cdir;
    private int rlim;
    private int clim;
    private int turn;
    private int maxTurns;
    private bool checksolution;

    static int GUESSESBEFOREASK  =  1000000;

    public signal void showsolvergrid ();
    public signal void showprogress (int guesses);

//~     public Solver (Controller control) {
//~         this.control = control;
//~     }
//~     public Solver (Model model) {
//~         this.model = model;
//~     }

//~     public void set_dimensions (int r, int c) {
//~         rows = r; cols = c; regionCount = r + c;
//~         grid = new My2DCellArray (r, c);
//~         solution = new My2DCellArray (r, c);
//~         regions = new Region[regionCount];

//~         for (int i = 0; i < regionCount; i++ ) {
//~             regions[i] = new Region (grid);
//~         }
//~     }

    public bool initialize (string[] rowclues, string[] colclues,
                            My2DCellArray? startgrid, My2DCellArray? solutiongrid) {

        if (rowclues.length != rows || colclues.length != cols) {
            warning ("row/col size mismatch");
            return false;
        }

        checksolution = false;

        if (solutiongrid != null) {
            checksolution = true;
            solution.copy (solutiongrid);
        }

        if (startgrid != null) {
            grid.copy (startgrid);
        } else {
            grid.set_all (CellState.UNKNOWN);
        }

        for (int r = 0; r < rows; r++ ) {
            regions[r].initialize (r, false, cols, rowclues[r]);
        }

        for (int c = 0; c < cols; c++ ) {
            regions[c + rows].initialize (c, true, rows, colclues[c]);
        }

        return valid ();
    }

    public bool valid () {
        foreach (Region r in regions) {
            if (r.inError) {
                return false;
            }
        }

        int rowTotal = 0;
        int colTotal = 0;

        for (int r = 0; r < rows; r++ ) {
            rowTotal += regions[r].blockTotal;
        }

        for (int c = 0; c < cols; c++ ) {
            colTotal += regions[rows + c].blockTotal;
        }

        return rowTotal == colTotal;
    }

    public int solve_it (bool debug,
                         bool use_advanced,
                         bool use_ultimate = true,
                         bool uniqueOnly = false,
                         bool stepwise = false) {

        int simpleresult = simplesolver (debug, true, checksolution, stepwise); //debug, log errors, check solution, step through solution one pass at a time

        if (simpleresult == 0 && use_advanced) {
            CellState[] gridstore =  new CellState[rows*cols];
            return advancedsolver (gridstore, debug, 9999, uniqueOnly, use_ultimate);
        }

        if (rows == 1) {
            stdout.printf (regions[0].to_string ());  //used for debugging
        }

        return simpleresult;
    }

    public bool get_hint () {
        //Solver must be initialised with current state of puzzle before calling.

        int pass = 1;

        while (pass <= 30) {
          //cycle through regions until one of them is changed then return
          //that region index.

            for (int i = 0; i < regionCount; i++ ) {
                if (regions[i].isCompleted) {
                    continue;
                }

                if (regions[i].solve (false, true)) {//run solve algorithm in hint mode
                    showsolvergrid ();
                    return true;
                }

                if (regions[i].inError) {
                    Utils.show_warning_dialog (_ ("A logical error has already been made  -  cannot hint"));
                    return false;
                }
            }

            pass++;
        }

        if (pass > 30) {
            if (solved ()) {
                Utils.show_info_dialog (_ ("Already solved"));
            } else {
                Utils.show_info_dialog (_ ("Cannot find hint"));
            }
        }

        return false;
    }

    private int simplesolver (bool debug,
                              bool logerror,
                              bool checksolution,
                              bool stepwise) {

        bool changed = true;
        int pass = 1;

        while (changed && pass < 1000) {
            //keep cycling through regions while at least one of them is changing
            changed = false;
            foreach (Region r in regions) {
                if (r.isCompleted) {
                    continue;
                }

                if (r.solve (debug, false)) {
                    changed = true; //no hinting
                }

                if (r.inError) {
                    if (debug) {
                        stdout.printf ("::" + r.message);
                    }
                    return  - 1;
                }

                if (checksolution && differsFromSolution (r)) {
                    stdout.printf (r.to_string ());
                    return  - 1;
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
            return pass;
        }

        if (pass > 1000) {
            return 999999;
        }

        return 0;
    }

    public bool solved () {
        foreach (Region r in regions) {
            if (!r.isCompleted) {
                return false;
            }
        }

        return true;
    }

    private bool differsFromSolution (Region r) {
        //use for debugging
        bool isColumn = r.isColumn;
        int index = r.index;
        int nCells = r.nCells;
        int solutionState, regionState;

        for (int i = 0; i < nCells; i++ ) {
            regionState = r.status[i];

            if (regionState == CellState.UNKNOWN) {
                continue;
            }

//~             solutionState = (solution.get_cell (isColumn ? i : index, isColumn ? index : i)) .state;
            solutionState = solution.get_data_from_rc (isColumn ? i : index, isColumn ? index : i);

            if (solutionState == CellState.EMPTY) {
                if (regionState == CellState.EMPTY) {
                    continue;
                }
            } else {//solutionState is FILLED
                if (regionState != CellState.EMPTY) {
                    continue;
                }
            }

            return true;
        }

        return false;
    }

    private int advancedsolver (CellState[] gridstore,
                                bool debug,
                                int maxGuesswork,
                                bool uniqueOnly,
                                bool useUltimate = true) {

        // single cell guesses, depth 1 (no recursion)
        // make a guess in each unknown cell in turn
        // if leads to contradiction mark opposite to guess,
        // continue simple solve, if still no solution start again.
        // if does not lead to solution leave unknown and choose another cell

        int simpleresult = 0;
        int wraps = 0;
        int guesses = 0;
        bool changed = false;
        int countChanged = 0;
        int initialmaxTurns = 3; //stay near edges until no more changes
        CellState initialcellstate = CellState.FILLED;

        rdir = 0; cdir = 1; rlim = rows; clim = cols;
        turn = 0; maxTurns = initialmaxTurns; guesses = 0;
        trialCell = {0, - 1, initialcellstate};

        this.saveposition (gridstore);

        while (true) {
            Utils.process_events ();
            trialCell = makeguess (trialCell); guesses++;

            if (trialCell.col == -1) { //run out of guesses
                if (changed) {
                    //stdout.printf (@"Changed $changed wraps: $wraps maxturns: $maxTurns\n");
                    if (countChanged>maxGuesswork) {
                        return 0;
                    }
                } else if (maxTurns == initialmaxTurns) {
                    maxTurns = (int.min (rows, cols)) / 2 + 2; //ensure full coverage
                } else if (trialCell.state == initialcellstate) {
                    trialCell = trialCell.invert (); //start making opposite guesses
                    maxTurns = initialmaxTurns; wraps = 0;
                } else {
                    break; //cant make progress
                }

                rdir = 0; cdir = 1; rlim = rows; clim = cols; turn = 0;
                changed = false;
                wraps++;
                continue;
            }

            grid.set_data_from_cell (trialCell);
            simpleresult = simplesolver (false, false, false, false); //only debug advanced part, ignore errors

            if (simpleresult > 0) {
                if (uniqueOnly) {//unique solutions must be solved by contradiction.
                    countChanged++;
                    simpleresult = 0;
                }

                break;
            }

            loadposition (gridstore); //back track

            if (simpleresult < 0) { //contradiction  -   insert opposite guess
                grid.set_data_from_cell (trialCell.invert ()); //mark opposite to guess
                changed = true; countChanged++; //worth trying another cycle
                simpleresult = simplesolver (false, false, false, false); //can we solve now?

                if (simpleresult == 0) {//no we cant
                    this.saveposition (gridstore); //update grid store
                    continue; //go back to start
                } else if (simpleresult > 0) {
                    break; // unique solution found
                } else {
                    return  -1; //starting point was invalid
                }
            } else {
                continue; //guess again
            }
        }

        //return vague measure of difficulty
        if (simpleresult > 0) {
            return simpleresult + countChanged * 20;
        }

        if (useUltimate) {
            return ultimate_solver (gridstore, guesses);
        } else {
            return 999999;
        }
    }

    private void saveposition (CellState[] gs) {
        //store grid in linearised form.
        for (int r = 0; r < rows; r++ ) {
            for (int c = 0; c < cols; c++ ) {
                gs[r * cols + c] = grid.get_data_from_rc (r, c);
            }
        }

        for (int i = 0; i < regionCount; i++ ) {
            regions[i].savestate ();
        }
    }

    private void loadposition (CellState[] gs) {
        for (int r = 0; r < rows; r++ ) {
            for (int c = 0; c < cols; c++ ) {
                grid.set_data_from_rc (r, c, gs[r * cols + c]);
            }
        }

        for (int i = 0; i < regionCount; i++ ) {
            regions[i].restorestate ();
        }
    }

    private Cell makeguess (Cell cell) {
        //Scan in spiral pattern from edges.  Critical cells most likely in this region

        uint r = cell.row;
        uint c = cell.col;

        while (true) {
            r += rdir; c += cdir; //only one changes at any one time

            if (cdir == 1 && c >= clim) {
                c--; cdir = 0; rdir = 1; r++;
            } else if (rdir == 1 && r >= rlim) {//across top  -  rh edge reached
                r--; rdir = 0; cdir = -1; c--;
            } else if (cdir == -1 && c < turn) {//down rh side  -  bottom reached
                c++; cdir = 0; rdir = -1; r--;
            } else if (rdir == -1 && r <= turn) {//back across bottom lh edge reached
                r++; turn++; rlim--; clim--; rdir = 0; cdir = 1;
            } //up lh side  -  top edge reached

            if (turn > maxTurns) {//stay near edge until no more changes
                cell.row = 0;
                cell.col = -1;
                break;
            }

            if (grid.get_data_from_rc (r, c) == CellState.UNKNOWN) {
                cell.row = r; cell.col = c;
                break;
            }
        }

        return cell;
    }

//~     public Cell get_cell (int r, int c) {
//~         return grid.get_cell (r, c);
//~     }


    private int ultimate_solver(CellState[] grid_store, int guesses) {
        //stdout.printf("Ultimate solver\n");
        int perm_reg = -1, max_value = 999999, advanced_result = -99, simple_result = -99;
        int limit = GUESSESBEFOREASK + guesses;

        loadposition (grid_store); //return to last valid state

        for (int i = 0; i < regionCount; i++) {
            regions[i].initialstate();
        }

        simplesolver (false,true,false,false); //make sure region state correct

        showsolvergrid();

        if (!Utils.show_confirm_dialog(_("Start Ultimate solver?\n This can take a long time and may not work"))) {
            return 999999;
        }

        Utils.process_events();
        CellState[] grid_store2 = new CellState[rows * cols];
        CellState[] guess = {};

        while (true) {
            perm_reg = choose_permute_region (ref max_value);
            if (perm_reg < 0) {
                stdout.printf("No perm region found\n");
                break;
            }

            int start;
            var p = regions[perm_reg].get_permutor(out start);

            if (p == null || p.valid == false) {
                stdout.printf ("No valid permutator generated\n");
                break;
            }

            bool isColumn = regions[perm_reg].isColumn;
            int idx = regions[perm_reg].index;

            //try advanced solver with every possible pattern in this range.

            for (int i = 0; i < regionCount; i++) {
                regions[i].initialstate();
            }

            saveposition(grid_store2);

            p.initialise();
            while (p.next()) {
                Utils.process_events(); //keep display from freezing
                guesses++;
                if (guesses > limit) {
                    if (Utils.show_confirm_dialog(_("This is taking a long time!")+"\n"+_("Keep trying?"))) {
                        limit+=GUESSESBEFOREASK;
                    } else {
                        return 999999;
                    }

                    Utils.process_events();
                }

                guess=p.get();

                grid.set_array (idx, isColumn, guess, start);
                simple_result = simplesolver (false, false, false, false);

                if (simple_result == 0) {
                    advanced_result = advancedsolver (grid_store, false, 99,false, false);

                    if (advanced_result > 0 && advanced_result < 999999) {
                        return advanced_result; //solution found
                    }
                } else if (simple_result > 0) {
                    return simple_result+guesses; //unlikely!
                }

                loadposition (grid_store2); //back track

                for (int i = 0; i < regionCount; i++) {
                    regions[i].initialstate();
                }
            }

            loadposition (grid_store2); //back track

            for (int i = 0; i < regionCount; i++) {
                regions[i].initialstate();
            }

            simplesolver (false, false, false, false);
        }

        return 0;
    }

    private int choose_permute_region (ref int max_value) {
        int best_value = -1, current_value, perm_reg = -1, edg;

        for (int r = 0; r < regionCount; r++ ) {
            current_value = regions[r].value_as_permute_region ();
            //weight towards edge regions

            if (current_value == 0) {
                continue;
            }

            if (r < rows) {
                edg = int.min (r, rows - 1 - r);
            } else {
                edg = int.min (r - rows, rows + cols - r - 1);
            }

            edg += 1;
            current_value = current_value * 100 / edg;

            if (current_value > best_value && current_value < max_value) {
                best_value = current_value;
                perm_reg = r;
            }
        }

        max_value = best_value;
        return perm_reg;
    }
}
}
