/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.Move {
    public static Move null_move = new Move (NULL_CELL, CellState.UNDEFINED);

    public Cell cell;
    public CellState previous_state;

    public Move (Cell _cell, CellState _previous_state) {
        cell = Cell () {
            row =_cell.row,
            col =_cell.col,
            state = _cell.state
        };

        previous_state = _previous_state;
    }

    public bool equal (Move m) {
        return m.cell.equal (cell) && m.previous_state == previous_state;
    }

    public Move clone () {
        return new Move (this.cell.clone (), this.previous_state);
    }

    public bool is_null () {
        return equal (Move.null_move);
    }

    public string to_string () {
        return "%u,%u,%u,%u".printf (cell.row, cell.col, cell.state, previous_state);
    }

    public static Move from_string (string? s) {
        if (s == null) {
            return Move.null_move;
        }

        var parts = s.split (",");
        if (parts == null || parts.length != 4) {
            return Move.null_move;
        }

        var row = (uint)(int.parse (parts[0]));
        var col = (uint)(int.parse (parts[1]));
        var state = (Gnonograms.CellState)(int.parse (parts[2]));
        var previous_state = (Gnonograms.CellState)(int.parse (parts[3]));

        if (row > Gnonograms.MAXSIZE ||
            col > Gnonograms.MAXSIZE ||
            state == Gnonograms.CellState.UNDEFINED ||
            previous_state == Gnonograms.CellState.UNDEFINED) {

            return Move.null_move;
        }

        Cell c = {row, col, state};
        return new Move (c, previous_state);
    }
}
