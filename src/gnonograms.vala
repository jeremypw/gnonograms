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
/*TODO - move enum and struct definitions elsewhere */
public enum GameState {
    SETTING,
    SOLVING,
    UNDEFINED;
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
    RADIAL,
    UNDEFINED
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

    public Cell invert() {
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
        return "Row %u, Col %u,  State %s".printf (row, col, state.to_string ());
    }
}

public struct Dimensions {
    uint width;
    uint height;
}


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

    public string to_string () {
        return cell.to_string () + " Previous state %s".printf (previous_state.to_string ());
    }
}

public const Cell NULL_CELL = {uint.MAX, uint.MAX, CellState.UNDEFINED};
public static int MAXSIZE = 50; // max number rows or columns
public static int MINSIZE = 5;
public static double MINFONTSIZE = 3.0;
public static double MAXFONTSIZE = 72.0;
public const string BLOCKSEPARATOR = ", ";
public const string BLANKLABELTEXT = _("?");
public static uint MAXGRADE = 12; //max grade level

private static double FRAME_WIDTH = 10.0;

public class App : Granite.Application {
    public Controller controller;
    private string game_name;
    private Dimensions dimensions;

    construct {
        application_id = "com.github.jeremypw.gnonograms-elementary";
        flags = ApplicationFlags.HANDLES_OPEN;

        program_name = _("Gnonograms");
        app_years = "display_working";
        app_icon = "gnonograms-3";

        build_data_dir = Build.DATADIR;
        build_pkg_data_dir = Build.PKGDATADIR;
        build_release_name = Build.RELEASE_NAME;
        build_version = Build.VERSION;
        build_version_info = Build.VERSION_INFO;

        app_launcher = "com.github.jeremypw.gnonograms-elementary.desktop";
        main_url = "https://github.com/jeremypw/gnonograms-elementary";
        bug_url = "https://github.com/jeremypw/gnonograms-elementary/issues";
        help_url = "";
        translate_url = "";
        about_authors = { "Jeremy Wootten <jeremywootten@gmail.com" };
        about_comments = "";
        about_translators = _("translator-credits");
        about_license_type = Gtk.License.GPL_3_0;

        SimpleAction quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (controller != null) {
                controller.quit (); /* Will save state */
            }
        });

        add_action (quit_action);
        add_accelerator ("<Control>q", "app.quit", null);

        game_name = "";
        dimensions = {15, 15};
    }

    public override void open (File[] files, string hint) {
        /* Only one game can be played at a time */
        var file = files[0];
        if (file == null) {
            return;
        }

        var fname = file.get_basename ();
        if (fname.has_suffix (".gno") || fname.has_suffix (".pattern")) {
            game_name = fname;
            /* TODO retrieve data from game */
            open_file (file);
        } else {
            activate ();
        }
    }

    public void open_file (File game) {
        controller = new Controller (game);
        this.add_window (controller.window);
    }

    public override void activate () {
        controller = new Controller ();
        this.add_window (controller.window);
    }
}
}

public static int main (string[] args) {
    var app = new Gnonograms.App ();
    return app.run (args);
}


