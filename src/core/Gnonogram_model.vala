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
    public GameState game_state { get; set; }
    public My2DCellArray solution_data { get; private set; }
    public My2DCellArray working_data { get; private set; }
    public uint rows { get; private set; }
    public uint cols  { get; private set; }

    public Dimensions dimensions {
        set {
            solution_data.dimensions = value;
            working_data.dimensions = value;
            rows = value.height;
            cols = value.width;
        }
    }

    public My2DCellArray display_data  {
        get {
            if (game_state == GameState.SETTING) {
                return solution_data;
            } else {
                return working_data;
            }
        }
    }

    public bool is_finished {
        get {
            return count_unsolved () == 0;
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

    public int count_unsolved () {
        int count=0;
        CellState cs;

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                cs = working_data.get_data_from_rc (r,c);

                if (cs == CellState.UNKNOWN) {
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

    public string get_label_text_from_solution (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return solution_data.data2text (idx, length, is_column);
    }

    public string get_label_text_from_working (uint idx, bool is_column) {
        uint length = is_column ? rows : cols;
        return working_data.data2text (idx, length, is_column);
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

    public void set_row_data_from_string_array (string[] row_clues) {
        assert (row_clues.length == rows);
        int row = 0;
        foreach (var clue in row_clues) {
            display_data.set_row (row, Utils.cellstate_array_from_string (clue));
            row++;
        }
    }
}
}
