/* Main function for gnonograms-elementary
 * Initialises environment and launches game
 * Copyright (C) 2010-2011  Jeremy Wootten
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

public enum GameState {
    SETTING,
    SOLVING;
}

public enum CellState {
    UNKNOWN,
    EMPTY,
    FILLED,
    ERROR,
    COMPLETED,
    ERROR_EMPTY,
    ERROR_FILLED,
    UNDEFINED;
}

public enum CellPatternType {
    NONE,
    RADIAL
}

public enum ButtonPress {
    LEFT_SINGLE,
    LEFT_DOUBLE,
    MIDDLE_SINGLE,
    MIDDLE_DOUBLE,
    RIGHT_SINGLE,
    RIGHT_DOUBLE,
    UNDEFINED
}

public struct Cell {
    public int row;
    public int col;
    public CellState state;

    public bool same_coords (Cell c) {
        return (this.row == c.row && this.col == c.col);
    }

    public void copy (Cell b) {
        this.row = b.row;
        this.col = b.col;
        this.state = b.state;
    }

    public Cell invert() {
        Cell c = { row, col, CellState.UNKNOWN };

        if (this.state == CellState.EMPTY) {
            c.state = CellState.FILLED;
        } else {
            c.state = CellState.EMPTY;
        }

        return c;
    }

    public string to_string () {
        return "Row %s, Col %s,  State %s").printf (row, col, state);
    }
}

public struct Move {
    public Cell previous;
    public Cell replacement;
}

Gnonogram_controller controller;

public static int main (string[] args) {
    string game_filename = "";
    string package_name = Resource.APP_GETTEXT_PACKAGE;

    if (args.length >= 2) { //a filename has been provided
        game_filename = args[1];

        if (!game_filename.has_suffix (".pattern") && !game_filename.has_suffix(".gno")) {
            game_filename = "";
        }
    }

    Gtk.init (ref args);
    Resource.init (args[0]);
    Intl.bindtextdomain (package_name, Resource.locale_dir);
    Intl.bind_textdomain_codeset (package_name, "UTF-8");
    Intl.textdomain (package_name);

    controller = new Gnonogram_controller (game_filename);

    Gtk.main ();
    return 0;
}


