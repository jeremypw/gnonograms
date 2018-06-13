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
 public abstract class AbstractSolver : GLib.Object {
    protected static uint MAX_PASSES = 200;
    protected Region[] regions;
    protected uint n_regions { get { return dimensions.length (); }}
    protected bool should_check_solution;

    public SolverState state { get; set; }

    public My2DCellArray grid { get; protected set; } // Shared with Regions which can update the contents
    public My2DCellArray solution { get; protected set; }
    public Cancellable? cancellable { get; set; }
    public bool cancelled {
        get {
            return cancellable != null ? cancellable.is_cancelled () : false;
        }
    }

    public bool unique_only { get; set; default = true;} /* Do not allow ambiguus solutions */
    public bool use_advanced { get; set; default = false;} /* Use advanced logic (trial and error) */
    public bool advanced_only { get; set; default = false;} /* Must need advanced logic */
    public bool human_only { get; set; default = true;} /* Limit solutions to those humanly achievable */

    public uint rows { get { return dimensions.height; }}
    public uint cols { get { return dimensions.width; }}
    protected Dimensions _dimensions;
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

    /** Set up solver for a particular puzzle. In addition to the clues, a starting point
      * and/or the correct solution may be provided (useful for debugging).
    **/
    protected virtual bool initialize (string[] row_clues,
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

    protected virtual void reinitialize_regions () {
        int index = 0;
        for (int r = 0; r < rows; r++) {
            regions[index++].set_to_initial_state ();
        }

        for (int c = 0; c < cols; c++) {
            regions[index++].set_to_initial_state ();
        }
    }

    protected virtual bool valid () {
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

    public virtual bool solved () {
        foreach (Region r in regions) {
            if (!r.is_completed) {
                return false;
            }
        }

        return true;
    }

    protected virtual bool differs_from_solution (Region r) {
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

    /** Initiate solving, specifying whether or not to use the advanced
      * procedures. Also specify whether in debugging mode and whether to solve one step
      * at a time (used for hinting if implemented).
    **/
    public Difficulty solve_clues (string[] row_clues,
                                   string[] col_clues,
                                   My2DCellArray? start_grid = null,
                                   My2DCellArray? solution_grid = null) {

        if (initialize (row_clues, col_clues, start_grid, solution_grid)) {
            return solve_it ();
        } else {
            state = SolverState.ERROR;
            return Difficulty.UNDEFINED;
        }
    }

    public void cancel () {
        cancellable.cancel ();
    }

    public virtual Gee.ArrayQueue<Move> hint (string[] row_clues, string[] col_clues, My2DCellArray working) {
        return new Gee.ArrayQueue<Move> ();
    }

    public virtual Gee.ArrayQueue<Move> debug (uint idx, bool is_column, string[] row_clues, string[] col_clues, My2DCellArray working) {
        return new Gee.ArrayQueue<Move> ();
    }

    protected abstract Difficulty solve_it ();
    public abstract void configure_from_grade (Difficulty grade);
}
}
