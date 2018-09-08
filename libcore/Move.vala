
/*
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

/* Move class records the current cell coordinates, its state and previous state */
public class Move {
    public static Move null_move = new Move (NULL_CELL, CellState.UNDEFINED);
    public Cell cell;
    public CellState previous_state;

    public Move (Cell cell, CellState previous_state) {
        this.cell.row = cell.row;
        this.cell.col = cell.col;
        this.cell.state = cell.state;
        this.previous_state = previous_state;
    }

    public bool equal (Move m) {
        return m.cell == this.cell && m.previous_state == this.previous_state;
    }

    public void copy (Move m) {
        this.cell.copy (m.cell);
        this.previous_state = m.previous_state;
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
}
