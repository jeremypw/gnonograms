
/* Entry point for gnonograms  - initializes application and launches game
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
public class Block {
    public int length;
    public bool is_complete;
    public bool is_error;

    public Block (int len, bool complete = false, bool error = false) {
        length = len;
        is_complete= complete;
        is_error = error;
    }

     public Block.null () {
        length = -1;
        is_complete = false;
        is_error = false;
    }

    public bool is_null () {
        return length < 0;
    }
}

public struct Cell {
    public uint row;
    public uint col;
    public CellState state;

    public bool same_coords (Cell c) {
        return (this.row == c.row && this.col == c.col);
    }

    public void copy (Cell b) {
        this.row = b.row;
        this.col = b.col;
        this.state = b.state;
    }

    public bool equal (Cell b) {
        return (
            this.row == b.row &&
            this.col == b.col &&
            this.state == b.state
        );

    }

    public Cell inverse () {
        Cell c = {row, col, CellState.UNKNOWN };

        if (this.state == CellState.EMPTY) {
            c.state = CellState.FILLED;
        } else {
            c.state = CellState.EMPTY;
        }

        return c;
    }

    public Cell clone () {
        return {row, col, state};
    }

    public string to_string () {
        return "Row %u, Col %u, State %s".printf (row, col, state.to_string ());
    }
}

public struct Dimensions {
    uint width;
    uint height;

    public uint rows () {
        return height;
    }

    public uint cols () {
        return width;
    }

    public uint area () {
        return width * height;
    }

    public uint length () {
        return width + height;
    }

    public bool equal (Dimensions other) {
        return width == other.width && height == other.height;
    }
}

public struct FilterInfo {
    string name;
    string pattern;
}
}
