/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.Move {
    // public static Move null_move = new Move (NULL_CELL, CellState.UNDEFINED);

    public Cell cell;
    public CellState previous_state;

    public Move.from_cell (Cell _cell, CellState _previous_state) {
        cell = Cell () {
            row =_cell.row,
            col =_cell.col,
            state = _cell.state
        };

        previous_state = _previous_state;
    }
    
    public Move (uint _row, uint _col, CellState _state, CellState _previous_state) {
        cell = Cell () {
            row =_row,
            col =_col,
            state = _state
        };

        previous_state = _previous_state;
    }

    public bool is_valid () {
        return (
            cell.row < MAXSIZE &&
            cell.col < MAXSIZE &&
            cell.state < CellState.COMPLETED &&
            previous_state < CellState.COMPLETED
        );
    }
    
    public bool equal (Move? m) {
        return m != null && (m.cell.equal (cell) && m.previous_state == previous_state);
    }

    public Move clone () {
        return new Move.from_cell (this.cell.clone (), this.previous_state);
    }

    // public bool is_null () {
    //     return equal (Move.null_move);
    // }

    public string to_string () {
        return "%u,%u,%u,%u".printf (cell.row, cell.col, cell.state, previous_state);
    }

    public static Move? from_string (string s) throws ConvertError {
        // if (s == null) {
        //     return Move.null_move;
        // }

        var parts = s.split (",");
        if (parts == null || parts.length != 4) {
            // return Move.null_move;
            throw new ConvertError.FAILED ("Incorrect number of parts");
        }

        var row = (uint)(int.parse (parts[0]));
        var col = (uint)(int.parse (parts[1]));
        var state = (uint)(int.parse (parts[2]));
        var previous_state = (uint)(int.parse (parts[3]));

        // if (row > MAXSIZE ||
        //     col > MAXSIZE ||
        //     state > CellState.COMPLETED ||
        //     previous_state > CellState.COMPLETED) {

        //     throw new ConvertError.FAILED ("Invalid location or state");
        // }

        // Cell c = {row, col, state};
        var mv = new Move (row, col, state, previous_state);
        if (mv.is_valid ()) {
            return mv;
        } else {
            throw new ConvertError.FAILED ("Invalid parameters");
        }
    }
}
