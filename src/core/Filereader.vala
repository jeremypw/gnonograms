/* Game file reader class for gnonograms
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
    /** PUBLIC **/
    public string err_msg = "";

    public File? game_file { get; set; default = null;}
    public GameState state { get; private set; default = GameState.UNDEFINED;}

    public int rows { get; private set; default = 0;}
    public int cols { get; private set; default = 0;}

    public string[] row_clues { get; private set; }
    public string[] col_clues { get; private set; }
    public string[] solution { get; private set; }
    public string[] working { get; private set; }

    public string name { get; private set; default = "";}
    public string date { get; private set; default = "";}
    public Difficulty difficulty { get; private set; default = Difficulty.UNDEFINED;}
    public string license { get; private set; default = "";}
    public string original_path { get; private set; default = "";}
    public string moves { get; private set; default = "";}

    public bool has_dimensions { get; private set; default = false;}
    public bool has_row_clues { get; private set; default = false;}
    public bool has_col_clues { get; private set; default = false;}
    public bool has_solution { get; private set; default = false;}
    public bool has_working { get; private set; default = false;}
    public bool has_state { get; private set; default = false;}
    public bool is_readonly { get; private set; default = true;}

    public bool valid {
        get {
            return err_msg == "";
        }
    }

    public Filereader (Gtk.Window? parent, string? load_dir_path, File? game) throws GLib.IOError {
        Object (game_file: game);

        if (game == null) {
            game_file = get_load_game_file (parent, load_dir_path);
        }

        if (game_file == null) {
            throw new IOError.CANCELLED ("Load game file dialog cancelled");
        }

        DataInputStream stream;
        try {
            var fstream = game_file.read (null);
            stream = new DataInputStream (fstream);
        } catch (GLib.Error e) {
            throw new IOError.FAILED ("Unable to open data stream");
        }

        parse_gnonogram_game_file (stream);

    }

    /** PRIVATE **/
    private File? get_load_game_file (Gtk.Window? parent, string? load_dir_path) {

        FilterInfo info = {_("Gnonogram puzzles"), "*" + Gnonograms.GAMEFILEEXTENSION};
        FilterInfo [] filters = {info};
        string? path = Utils.get_file_path (
                            parent,
                            Gnonograms.FileChooserAction.OPEN,
                            _("Choose a puzzle"),
                            filters,
                            load_dir_path,
                            null
                        );

        if (path == null || path == "") {
            return null;
        } else {
            return File.new_for_path (path);
        }
    }

    private void parse_gnonogram_game_file (DataInputStream stream) throws GLib.IOError {
        size_t header_length, body_length;
        string[] headings = {};
        string[] bodies = {};

        stream.read_upto ("[", 1, out header_length, null);
        stream.read_byte ();

        try {
            while (true) {
                    headings += stream.read_upto ("]", 1, out header_length, null);
                    stream.read_byte ();
                    bodies += stream.read_upto ("[", 1, out body_length, null);
                    stream.read_byte ();

                if (header_length == 0 || body_length == 0) {
                    break;
                }
            }

        } catch (GLib.Error e) {
            /* Ignore read error caused by end of file */
        }

        if (!parse_gnonogram_headings_and_bodies (headings, bodies)) {
            throw new IOError.INVALID_DATA ("Game file could not be parsed - %s", err_msg);
        }
    }

    private bool parse_gnonogram_headings_and_bodies (string[] headings, string[] bodies) {
        bool in_error = false;
        int index = 0;

        var hl = headings.length;
        var bl = bodies.length;

        if (hl < 3 || bl < 3 || hl != bl) { /* Need at least dimensions and clues */
            return false;
        }

        foreach (var heading in headings) {
            string body = bodies[index];
            index++;

            if (heading == null) {
                continue;
            }

            if (heading.length > 3) {
                heading = heading.slice (0, 3);
            }

            switch (heading.up ()) {
                case "DIM":
                    in_error = !get_gnonogram_dimensions (body);
                    break;

                case "ROW":
                    row_clues = get_gnonogram_clues (body, cols);

                    if (row_clues.length != rows) {
                        err_msg = "Wrong number of row clues - " + err_msg;
                        in_error = true;
                    } else {
                        has_row_clues = true;
                    }

                    break;

                case "COL":
                    col_clues = get_gnonogram_clues (body, rows);

                    if (col_clues.length != cols) {
                        err_msg = "Wrong number of column clues -" + err_msg;
                        in_error = true;
                    } else {
                        has_col_clues = true;
                    }

                    break;

                case "SOL":
                    in_error = !get_gnonogram_cellstate_array (body, true);
                    break;

                case "WOR":
                    in_error = !get_gnonogram_cellstate_array (body, false);
                    break;

                case "STA":
                    in_error = !get_gnonogram_state (body);
                    break;

                case "DES":
                    in_error = !get_game_description (body);
                    break;

                case "LOC":
                    in_error = !get_readonly (body);
                    break;

                case "ORI":
                    in_error = !get_original_game_path (body);
                    break;

                case "HIS":
                    moves = body;
                    break;

                default:
                    /* Ignore unsupported headings e.g. from other versions */
                    break;
            }
        }

        return !in_error;
    }

    private bool get_gnonogram_dimensions (string? body) {
        if (body == null) {
            err_msg = "No dimensions given";
            return false;
        }

        string[] s = Utils.remove_blank_lines (body.split ("\n"));

        if (s.length != 2) {
            err_msg = "Wrong number of dimensions";
            return false;
        }

        rows = int.parse (s[0]);
        cols = int.parse (s[1]);
        has_dimensions = true;

        return (rows > 0 && cols > 0);
    }

    private string[] get_gnonogram_clues (string? body, int max_block) {
        string [] clues = {};

        if (body == null) {
            err_msg = "No clues given";
            return {};
        }

        string[] clue_strings = Utils.remove_blank_lines (body.split ("\n"));

        if (clue_strings == null || clue_strings.length < 1) {
            err_msg = _("Missing clues");
            return {};
        }

        foreach (var clue_string in clue_strings) {
            string? clue = parse_gnonogram_clue (clue_string, max_block);

            if (clue == null) {
                err_msg = _("Invalid clue");
                return {};
            } else {
                clues += clue;
            }
        }

        return clues;
    }

    private bool get_gnonogram_cellstate_array (string? body, bool is_solution) {
        if (body == null) {
            err_msg = _("Solution grid or working grid missing");
            return false;
        }

        string[] row_strings = Utils.remove_blank_lines (body.split ("\n"));

        if (row_strings == null || row_strings.length != rows) {
            err_msg = _("Wrong number of rows in solution or working grid");
            return false;
        }

        foreach (var row in row_strings) {
            CellState[] states = Utils.cellstate_array_from_string (row);

            if (states.length != cols) {
                err_msg = _("Wrong number of columns in solution or working grid");
                return false;
            }

            if (is_solution) {
                foreach (var state in states) {
                    if (!(state in (CellState.EMPTY | CellState.FILLED))) {
                        err_msg = _("Invalid cell state");
                        return false;
                    }
                }
            }
        }

        if (is_solution) {
            solution = row_strings;
            has_solution = true;
        } else {
            working = row_strings;
            has_working = true;
        }

        return true;
    }

    private bool get_gnonogram_state (string? body) {
        /* Default to SOLVING state to avoid inadvertently showing solution */
        state = GameState.SOLVING;

        if (body != null) {
            string[] s = Utils.remove_blank_lines (body.split ("\n"));

            if (s != null && s.length == 1) {
                var state_string = s[0];

                if (state_string.up ().contains ("SETTING")) {
                    state = GameState.SETTING;
                }
            }
        }

        return true;
    }

    /** First four lines of description must be in order @name, @date, @score (difficulty or grade).
      * Missing data must be represented by blank lines.
    **/
    private bool get_game_description (string? body) {
        if (body == null) {
            return true;
        }

        string[] s = Utils.remove_blank_lines (body.split ("\n"));

        if (s.length >= 1) {
            name = Uri.unescape_string (s[0]);
        }

        if (s.length >= 2) {
            date = s[1];
        }

        if (s.length >= 3) {
            var grade = s[2].strip ();
            if (grade.length == 1 && grade[0].isdigit ()) {
                difficulty = (Difficulty)(int.parse (grade));
            } else {
                difficulty = Difficulty.UNDEFINED;
            }
        }

        return true;
    }

    private bool get_readonly (string? body) {
        if (body == null) {
            return true; /* Not mandatory */
        }

        string[] s = Utils.remove_blank_lines (body.split ("\n"));

        bool result = true;
        if (s.length >= 1) {
            bool.try_parse (s[0].down (), out result);
        }

        is_readonly = result;

        return true;
    }

    private bool get_original_game_path (string? body) {
        string result = "";

        if (body != null) {
            string[] s = Utils.remove_blank_lines (body.split ("\n"));

            if (s.length >= 1) {
                result = s[0];
            }
        }

        original_path = result;

        return true;
    }

    private string? parse_gnonogram_clue (string line, int maxblock) {
        string[] blocks = Utils.remove_blank_lines (line.split_set (", "));

        if (blocks == null) {
            return null;
        }

        int b, zero_count = 0;
        int remaining_space = maxblock;
        StringBuilder sb = new StringBuilder ();

        foreach (var block in blocks) {
            b = int.parse (block);

            if (b == 0 && zero_count > 0) {
                continue;
            } else {
                zero_count++;
            }

            if (b < 0 || b > remaining_space) {
                return null;
            }

            sb.append (b.to_string ());

            if (b > 0) {
                remaining_space -= (b + 1);
            }

            sb.append (Gnonograms.BLOCKSEPARATOR);
        }

        sb.truncate (sb.len - BLOCKSEPARATOR.length); // remove trailing seperator

        return sb.str;
    }
}
}
