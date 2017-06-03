/* Game file reader class for gnonograms-elementary
 * Copyright (C) 2010-2017  Jeremy Wootten
 *
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 *  Jeremy Wootten  < jeremwootten@gmail.com >
 */

namespace Gnonograms {
public class Filereader : Object {

    public File? game_file {get; private set; default = null;}
    public int rows {get; private set; default = 0;}
    public int cols {get; private set; default = 0;}
    public string[] row_clues {get; private set;}
    public string[] col_clues {get; private set;}
    public string[] solution {get; private set;}
    public string[] working {get; private set;}
    public GameState state {get; private set; default = GameState.UNDEFINED;}
    public string name {get; private set; default = "";}
    public string author {get; private set; default = "";}
    public string date {get; private set; default = "";}
    public string score {get; private set; default = "";}
    public string license {get; private set; default = "";}

    public bool has_dimensions {get; private set; default = false;}
    public bool has_row_clues {get; private set; default = false;}
    public bool has_col_clues {get; private set; default = false;}
    public bool has_solution {get; private set; default = false;}
    public bool has_working {get; private set; default = false;}
    public bool has_state {get; private set; default = false;}

    public string err_msg = "";

    public bool valid {
        get {
            return err_msg == "";
        }
    }

    public Filereader (File? game) throws GLib.Error {
        Object (game_file: game);

        if (game == null) {
            game_file = Utils.get_game_file (
                            Gtk.FileChooserAction.OPEN,
                            _("Choose a puzzle"),
                            {_("Gnonogram puzzles")},
                            {"*" + Gnonograms.GAMEFILEEXTENSION},
                            get_app ().load_game_dir
            );
        }

        parse_gnonogram_game_file (Utils.open_data_input_stream (game_file));
    }


    private bool parse_gnonogram_game_file (DataInputStream stream) throws GLib.Error {
        size_t header_length, body_length;
        string[] headings = {};
        string[] bodies = {};

            stream.read_until ("[", out header_length, null);
            while (true) {
                headings += stream.read_until ("]", out header_length, null);
                bodies += stream.read_until ("[", out body_length, null);
                if (header_length == 0  ||  body_length == 0) {
                    break;
                }
            }

        return parse_gnonogram_headings_and_bodies (headings, bodies);
    }

    private bool parse_gnonogram_headings_and_bodies (string[] headings, string[] bodies) {
        int n = headings.length;
        bool in_error = false;

        for (int i = 0; i < n; i++) {
            string heading = headings[i];

            if (heading == null) {
                continue;
            }

            if (heading.length > 3) {
                heading = heading.slice (0, 3);
            }

            switch (heading.up ()) {
                case "DIM" :
                    in_error = !get_gnonogram_dimensions(bodies[i]); break;
                case "ROW" :
                    in_error = !get_gnonogram_clues(bodies[i], false); break;
                case "COL" :
                    in_error = !get_gnonogram_clues(bodies[i], true); break;
                case "SOL" :
                    in_error = !get_gnonogram_cellstate_array(bodies[i], true); break;
                case "WOR" :
                    in_error = !get_gnonogram_cellstate_array(bodies[i], false); break;
                case "STA" :
                    in_error = !get_gnonogram_state(bodies[i]); break;
                case "DES" :
                    in_error = !get_game_description(bodies[i]); break;
                case "LIC" :
                    in_error = !get_game_license(bodies[i]); break;
                default :
                    err_msg = _("Unrecognized heading");
                    in_error = true;
                    break;
            }
        }

        return !in_error;
    }

    private bool get_gnonogram_dimensions (string? body) {
        if (body == null) {
            err_msg = _("No dimensions given");
            return false;
        }

        string[] s = Utils.remove_blank_lines (body.split ("\n"));
        if (s.length != 2) {
            err_msg = _("Wrong number of dimensions");
            return false;
        }

        rows = int.parse (s[0]);
        cols = int.parse (s[1]);
        has_dimensions = true;
        return (rows > 0 && cols > 0);
    }

    private bool get_gnonogram_clues (string? body, bool is_column) {
        string[] arr = {};

        if (body == null) {
            err_msg = _("No clues given");
            return false;
        }

        string[] s = Utils.remove_blank_lines (body.split ("\n"));

        if (s == null || s.length < 1) {
            err_msg = _("Missing clues");
            return false;
        }

        for (int i = 0; i < s.length; i++) {
            string? clue = parse_gnonogram_clue (s[i], is_column);

            if (clue == null) {
                err_msg = _("Invalid clue");
                return false;
            } else {
                arr+= clue;
            }
        }

        if (is_column) {
            if (arr.length != cols) {
                err_msg = _("Wrong number of column clues");
                return false;
            }

            col_clues = arr;
            has_col_clues = true;
        } else {
            if (arr.length != rows) {
                err_msg = _("Wrong number of row clues");
                return false;
            }

            row_clues = arr;
            has_row_clues = true;
        }
        return true;
    }

    private bool get_gnonogram_cellstate_array (string? body, bool is_solution) {
        if (body == null) {
            err_msg = _("Solution grid or working grid missing");
            return false;
        }

        string[] s = Utils.remove_blank_lines (body.split ("\n"));

        if (s == null || s.length != rows) {
            err_msg = _("Wrong number of rows in solution or working grid");
            return false;
        }

        for (int i = 0; i < s.length; i++) {
            CellState[] arr = Utils.cellstate_array_from_string (s[i]);
            if (arr.length != cols) {
                err_msg = _("Wrong number of columns in solution or working grid");
                return false;
            }
            if (is_solution) {
                for (int c = 0; c < cols; c++) {
                    if (arr[c] != CellState.EMPTY && arr[c] != CellState.FILLED) {
                        err_msg = _("Invalid cell state");
                        return false;
                    }
                }
            }
        }
        if (is_solution) {
            solution = s;
            has_solution = true;
        } else {
            working = s;
            has_working = true;
        }

        return true;
    }

    private bool get_gnonogram_state (string? body) {
        if (body == null) {
            err_msg = _("Missing game state");
            return false;
        }

        string[] s = Utils.remove_blank_lines (body.split("\n"));

        if (s == null || s.length != 1) {
            err_msg = _("Could not determine game state in loaded game file");
            return false;
        }

        var state_string = s[0];

        if (state_string.up ().contains ("SETTING")) {
            state = GameState.SETTING;
        } else if (state_string.up ().contains ("SOLVING")) {
            state = GameState.SOLVING;
        } else {
            err_msg = _("Invalid game state '%s' in loaded game file").printf (state);
            return false;
        }

        return true;
    }

    private bool get_game_description (string? body) {
        if (body == null) {
            return true;
        }

        string[] s = Utils.remove_blank_lines (body.split("\n"));

        if (s.length >= 1) {
            name = Uri.unescape_string (s[0]);
        }

        if (s.length >= 2) {
            author = Uri.unescape_string (s[1]);
        }

        if (s.length >= 3) {
            date = s[2];
        }

        if (s.length >= 4) {
            score = s[3];
        }

        return true;
    }

    private bool get_game_license (string? body) {
        if (body == null) {
            return true; /* Not mandatory */
        }

        string[] s = Utils.remove_blank_lines (body.split("\n"));

        if (s.length >= 1) {
            if (s[0].length > 50) {
                license = s[0].slice (0, 50);
            } else {
                license = s[0];
            }
        }

        return true;
    }

    private string? parse_gnonogram_clue (string line, bool is_column) {
        string[] s = Utils.remove_blank_lines (line.split_set (", "));
        int b, zero_count = 0;
        int maxblock = is_column ? rows : cols;

        if (s == null) {
            return null;
        }

        StringBuilder sb = new StringBuilder ();
        for (int i = 0; i < s.length; i++) {
            b = int.parse(s[i]);

            if (b < 0 || b > maxblock) {
                return null;
            }

            if (b == 0 && zero_count > 0) {
                continue;
            } else {
                zero_count++;
            }

            sb.append(s[i] + Gnonograms.BLOCKSEPARATOR);
        }

        sb.truncate (sb.len - 1);
        return sb.str;
    }
}
}
