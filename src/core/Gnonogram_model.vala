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
public class Model : GLib.Object {
    /** PUBLIC **/
    public signal void changed ();

    public GameState game_state { get; set; default = GameState.UNDEFINED; }
    public Dimensions dimensions { get; set; }
    public uint rows { get {return dimensions.height;} }
    public uint cols { get {return dimensions.width;} }

    public My2DCellArray display_data {
        get {
            return game_state == GameState.SETTING ? solution_data : working_data;
        }
    }

    public bool is_finished {
        get {
            return count_state (GameState.SOLVING, CellState.UNKNOWN) == 0;
        }
    }

    private My2DCellArray solution_data { get; set; }
    private My2DCellArray working_data { get; set; }

    construct {
        notify["dimensions"].connect (() => {
            solution_data = new My2DCellArray (dimensions, CellState.EMPTY);
            working_data = new My2DCellArray (dimensions, CellState.UNKNOWN);
            changed ();
        });

        notify["game-state"].connect (() => {
            changed ();
        });
    }

    public int count_errors () {
        CellState cs;
        int count = 0;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols;c++) {
                cs = working_data.get_data_from_rc (r,c);

                if (cs != CellState.UNKNOWN && cs != solution_data.get_data_from_rc (r, c)) {
                    count++;
                }
            }
        }

        return count;
    }

    private int count_state (GameState game_state, CellState cell_state) {
        int count=0;
        CellState cs;
        My2DCellArray arr = game_state == GameState.SOLVING ? working_data : solution_data;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                cs = arr.get_data_from_rc (r,c);

                if (cs == cell_state) {
                    count++;
                }
            }
        }

        return count;
    }

    public void clear () {
        blank_solution ();
        blank_working ();
    }

    public void blank_solution () {
        solution_data.set_all (CellState.EMPTY);
        changed ();
    }

    public void blank_working () {
        working_data.set_all (CellState.UNKNOWN);
        changed ();
    }

    public bool is_blank (GameState state) {
        if (state == GameState.SOLVING) {
            return count_state (state, CellState.EMPTY) + count_state (state, CellState.FILLED) == 0;
        } else {
            return count_state (state, CellState.FILLED) == 0;
        }
    }

    public bool working_matches_clues () {
        int index = 0;
        foreach (string clue in get_row_clues ()) {
            if (clue != get_label_text_from_working (index, false)) {
                return false;
            }

            index++;
        }

        index = 0;
        foreach (string clue in get_col_clues ()) {
            if (clue != get_label_text_from_working (index, true)) {
                return false;
            }

            index++;
        }

        return true;
    }

    public string[] get_row_clues () {
        return get_clues (false);
    }

    public string[] get_col_clues () {
        return get_clues (true);
    }

    private string[] get_clues (bool is_column) {
        var dim = is_column ? cols : rows;
        var texts = new string [dim];

        for (uint index = 0; index < dim; index++) {
            texts[index] = get_label_text_from_solution (index, is_column);
        }

        return texts;
    }

    public string get_label_text_from_solution (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return solution_data.data2text (idx, length, is_column);
    }

    public string get_label_text_from_working (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return working_data.data2text (idx, length, is_column);
    }

    public Gee.ArrayList<Block> get_complete_blocks_from_working (uint index, bool is_column) {
        var csa = new CellState[is_column ? rows : cols];
        working_data.get_array (index, is_column, ref csa);
        return Utils.complete_block_array_from_cellstate_array (csa);
    }

    public bool get_complete (uint idx, bool is_column) {
        var csa = new CellState[is_column ? rows : cols];
        working_data.get_array (idx, is_column, ref csa);

        foreach (CellState cs in csa) {
            if (cs == CellState.UNKNOWN) {
                return false;
            }
        }

        return true;
    }

    public void set_data_from_cell (Cell cell) {
        display_data.set_data_from_cell (cell);
        changed ();
    }

    public void set_data_from_rc (uint r, uint c, CellState state) {
        display_data.set_data_from_rc (r, c, state);
        changed ();
    }

    public void set_solution_from_array (My2DCellArray array) {
        solution_data.copy (array);
        changed ();
    }
    public void set_working_from_array (My2DCellArray array) {
        working_data.copy (array);
        changed ();
    }

    public CellState get_data_for_cell (Cell cell) {
        return display_data.get_data_for_cell (cell);
    }

    public CellState get_data_from_rc (uint r, uint c) {
        return display_data.get_data_from_rc (r, c);
    }

    private void set_row_data_from_string_array (string[] row_data_strings, My2DCellArray array) {
        assert (row_data_strings.length == rows);
        int row = 0;
        foreach (var row_string in row_data_strings) {
            array.set_row (row, Utils.cellstate_array_from_string (row_string));
            row++;
        }

        changed ();
    }

    public void set_working_data_from_string_array (string[] row_data_strings) {
        set_row_data_from_string_array (row_data_strings, working_data);
    }

    public void set_solution_data_from_string_array (string[] row_data_strings) {
        set_row_data_from_string_array (row_data_strings, solution_data);
    }

    public void copy_to_working_data (My2DCellArray grid) {
        working_data.copy (grid);
        changed ();
    }

    public void copy_to_solution_data (My2DCellArray grid) {
        solution_data.copy (grid);
        changed ();
    }

    public My2DCellArray copy_working_data () {
        var grid = new My2DCellArray (dimensions, CellState.UNKNOWN);
        grid.copy (working_data);
        return grid;
    }

    public My2DCellArray copy_solution_data () {
        var grid = new My2DCellArray (dimensions, CellState.UNKNOWN);
        grid.copy (solution_data);
        return grid;
    }
}
}
