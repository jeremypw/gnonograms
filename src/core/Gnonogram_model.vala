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
    public GameState game_state {
        set {
            if (value == GameState.SETTING) {
                display_data = solution_data;
            } else {
                display_data = working_data;
            }
        }
    }

    public My2DCellArray solution_data { get; private set; }
    public My2DCellArray working_data { get; private set; }
    public uint rows { get {return dimensions.height;} }
    public uint cols  { get {return dimensions.width;} }

    private Dimensions _dimensions;
    public Dimensions dimensions {
        set {
            _dimensions = value;
            solution_data.dimensions = value;
            working_data.dimensions = value;
        }

        get {
            return _dimensions;
        }
    }

    private My2DCellArray _display_data;
    public My2DCellArray display_data  {
        get {
            return _display_data;
        }

        private set {
            _display_data = value;
        }
    }

    public bool is_finished {
        get {
            return count_state (GameState.SOLVING, CellState.UNKNOWN) == 0;
        }
    }

    construct {
        solution_data = new My2DCellArray ({ MAXSIZE, MAXSIZE }, CellState.EMPTY);
        working_data = new My2DCellArray ({ MAXSIZE, MAXSIZE }, CellState.UNKNOWN);
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
    }

    public void blank_working () {
        working_data.set_all (CellState.UNKNOWN);
    }

    public bool is_blank (GameState state) {
        if (state == GameState.SOLVING) {
            return count_state (state, CellState.EMPTY) + count_state (state, CellState.FILLED) == 0;
        } else {
            return count_state (state, CellState.FILLED) == 0;
        }
    }

    public string get_label_text_from_solution (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return solution_data.data2text (idx, length, is_column);
    }

    public string get_label_text_from_working (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return working_data.data2text (idx, length, is_column);
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
    }

    public void set_data_from_rc (uint r, uint c, CellState state) {
        display_data.set_data_from_rc (r, c, state);
    }

    public void set_solution_from_array (My2DCellArray array) {
        solution_data.copy (array);
    }
    public void set_working_from_array (My2DCellArray array) {
        working_data.copy (array);
    }

    public CellState get_data_for_cell (Cell cell) {
        return display_data.get_data_for_cell (cell);
    }

    public CellState get_data_from_rc (uint r, uint c) {
        return display_data.get_data_from_rc (r, c);
    }

    private void set_row_data_from_string_array (string[] row_clues, My2DCellArray array) {
        assert (row_clues.length == rows);
        int row = 0;
        foreach (var clue in row_clues) {
            array.set_row (row, Utils.cellstate_array_from_string (clue));
            row++;
        }
    }

    public void set_working_data_from_string_array (string[] row_clues) {
        set_row_data_from_string_array (row_clues, working_data);
    }

    public void set_solution_data_from_string_array (string[] row_clues) {
        set_row_data_from_string_array (row_clues, solution_data);
    }
}
}
