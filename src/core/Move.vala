
/* Entry point for gnonograms-elementary  - initialises application and launches game
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

public class Move {
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

    public string to_string () {
        return cell.to_string () + " Previous state %s".printf (previous_state.to_string ());
    }
}
}
