/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.Block {
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

public struct Gnonograms.Cell {
    public uint row;
    public uint col;
    public CellState state;

    public bool same_coords (Cell c) {
        return (this.row == c.row && this.col == c.col);
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
        return { row, col, state };
    }

    public string to_string () {
        return "Row %u, Col %u, State %s".printf (row, col, state.to_string ());
    }
}

public struct Gnonograms.Dimensions {
    uint width;
    uint height;

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

public struct Gnonograms.FilterInfo {
    string name;
    string[] patterns;
}

public struct Gnonograms.Range { //can use for filled subregions or ranges of filled and unknown cells
    public int start;
    public int end;
    public int filled;
    public int unknown;

    public int length () {
        return end - start + 1;
    }
}
