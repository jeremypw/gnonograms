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
public class Filereader {

    public string game_path = "";
    public int rows = 0;
    public int cols = 0;
    public string[] row_clues;
    public string[] col_clues;
    public string state;
    public string name = "";
    public string author = "";
    public string date = "";
    public string score = "";
    public string license = "";
    public bool in_error = false;
    public bool has_dimensions = false;
    public bool has_row_clues = false;
    public bool has_col_clues = false;
    public bool has_solution = false;
    public bool has_working = false;
    public bool has_state = false;
    public string[] solution;
    public string[] working;
    public string err_msg = "";

    private DataInputStream stream;
    private bool is_game;
    private string[] headings;
    private string[] bodies;

    public Filereader (string fname = "") {
        if (fname == "") {
            ask_game_path ();
        } else {
            game_path = fname;
        }

        is_game = true;
    }

    public void ask_game_path () {
        game_path = Utils.get_file_path (
            Gtk.FileChooserAction.OPEN,
            _("Choose a puzzle"),
            {_("Gnonogram puzzles")},
            {"*" + Gnonograms.GAMEFILEEXTENSION},
            (GLib.Application.get_default () as App).game_dir
        );
    }

    public bool open_data_input_stream () {
        stream =  Utils.open_data_input_stream (game_path);
        if (stream == null) {
            err_msg = _("Cannot open file");
            return false;
        } else {
            return true;
        }
    }

    public bool parse_game_file () {
        return parse_gnonogram_game_file ();
    }

    private bool parse_gnonogram_game_file () {
        size_t header_length, body_length;
        try {
            stream.read_until ("[", out header_length, null);
            while (true) {
                headings += stream.read_until ("]", out header_length, null);
                bodies += stream.read_until ("[", out body_length, null);
                if (header_length == 0  ||  body_length == 0) {
                    break;
                }
            }
        } catch (Error e) {
            err_msg = e.message;
            return false;
        }
        return parse_gnonogram_headings_and_bodies ();
    }

    private bool parse_gnonogram_headings_and_bodies () {
        int n = headings.length;

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
            if (in_error) {
                return false;
            }
        }
        return true;
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
            err_msg = _("Invalid game state");
            return false;
        }
        state = s[0];
        if (state == (GameState.SETTING).to_string () || state == (GameState.SOLVING).to_string ()) {
            has_state = true;
        } else {
            err_msg = _("Invalid game state");
            return false;
        }

        return true;
    }

    private bool get_game_description (string? body) {
        if (body == null) {
            err_msg = _("Missing description");
            return false;
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
            err_msg = _("Missing license");
            return false;
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
