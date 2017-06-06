/* Utility functions for gnonograms-elementary
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
namespace Utils {
    public static string[] remove_blank_lines (string[] sa) {
        string[] result = {};

        foreach (string s in sa) {
            string ss = s.strip ();
            if (ss != "") {
                result += ss;
            }
        }

        return result;
    }

    public int[] block_array_from_clue (string s) {
        string[] clues = remove_blank_lines (s.split_set (", "));

        if (clues.length == 0) {
            return {0};
        } else {
            int[] blocks = new int[clues.length];
            int index = 0;
            foreach (string clue in clues) {
                blocks[index++] = int.parse (clue);
            }

            return blocks;
        }
    }

    public int blockextent_from_clue (string s) {
        int[] blocks = block_array_from_clue (s);
        int extent = 0;

        foreach (int block in blocks) {
            extent += block + 1;
        }

        extent--;
        return extent;
    }

    public string block_string_from_cellstate_array (CellState[] cs) {
        StringBuilder sb = new StringBuilder ("");
        int count = 0, blocks = 0;
        bool counting = false;

        for (int i = 0; i < cs.length; i++) {
            if (cs[i] == CellState.EMPTY) {
                if (counting) {
                    sb.append (count.to_string() + BLOCKSEPARATOR);
                    counting = false;
                    count = 0;
                    blocks++;
                }
            } else if (cs[i] == CellState.FILLED) {
                counting = true;
                count++;
            } else {
                return BLANKLABELTEXT;
            }
        }

        if (counting) {
            sb.append (count.to_string () + BLOCKSEPARATOR);
            blocks++;
        }

        if (blocks == 0) {
            sb.append ("0");
        } else {
            sb.truncate (sb.len - BLOCKSEPARATOR.length);
        }

        return sb.str;
    }

    public CellState[] cellstate_array_from_string (string s) {
        CellState[] cs = {};
        string[] data = remove_blank_lines (s.split_set (BLOCKSEPARATOR));

        for (int i = 0; i < data.length; i++) {
            cs += (CellState)(int.parse (data[i]).clamp (0, 6));
        }

        return cs;
    }

    public string string_from_cellstate_array (CellState[] cs) {
        if (cs == null) {
            return "";
        }

        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < cs.length; i++) {
            sb.append (((int)cs[i]).to_string ());
            sb.append (" ");
        }

        return sb.str;
    }

    public string hex_string_from_cellstate_array (CellState[] sa) {
        StringBuilder sb = new StringBuilder ("");
        int length = sa.length;
        int e = 0, m = 1, count = 0;

        for (int i = length - 1; i >= 0; i--) {
            count++;
            e += ((int)(sa[i]) - 1) * m;
            m = m * 2;
            if (count == 4 || i == 0) {
                sb.prepend (int2hex (e));
                count = 0; m = 1; e = 0;
            }
        }

        return sb.str;
    }

    private const string[] letters = {"A","B","C","D","E","F"};
    private string int2hex (int i) {
        if (i > 15 || i < 0) {
            return "X";
        } else if (i <= 9) {
            return i.to_string ();
        } else {
            return letters[i - 10];
        }
    }

    public static int show_dlg (string msg, Gtk.MessageType type, Gtk.ButtonsType buttons, Gtk.Window? parent = null) {
        var dialog = new Gtk.MessageDialog (parent,
                                            Gtk.DialogFlags.MODAL,
                                            type,
                                            buttons,
                                            "%s", msg);

        dialog.set_position (Gtk.WindowPosition.MOUSE);
        int response = dialog.run ();
        dialog.destroy ();
        return response;
    }

    public static void show_info_dialog (string msg, Gtk.Window? parent = null) {
        show_dlg (msg, Gtk.MessageType.INFO, Gtk.ButtonsType.CLOSE, parent);
    }

    public static void show_warning_dialog (string msg, Gtk.Window? parent = null) {
        show_dlg (msg, Gtk.MessageType.WARNING, Gtk.ButtonsType.CLOSE, parent);
    }

    public static void show_error_dialog (string msg, Gtk.Window? parent = null) {
        show_dlg (msg, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, parent);
    }

    public static bool show_confirm_dialog(string msg, Gtk.Window? parent = null) {
        return show_dlg (msg ,Gtk.MessageType.WARNING, Gtk.ButtonsType.YES_NO, parent)==Gtk.ResponseType.YES;
    }

    public static File? get_load_game_file (Gtk.Window? parent = null) {
        string path = get_file_path (parent,
            Gtk.FileChooserAction.OPEN,
            _("Choose a puzzle"),
            {_("Gnonogram puzzles")},
            {"*" + Gnonograms.GAMEFILEEXTENSION},
            get_app ().load_game_dir
        );

        if (path == "") {
            return null;
        } else {
            return File.new_for_path (path);
        }
    }

    public static string get_save_file_path (Gtk.Window? parent = null) {
        return get_file_path (parent,
            Gtk.FileChooserAction.SAVE,
            _("Name and save this puzzle"),
            {_("Gnonogram puzzles")},
            {"*" + Gnonograms.GAMEFILEEXTENSION},
            get_app ().save_game_dir
        );
    }

    private static string get_file_path (Gtk.Window? parent,
        Gtk.FileChooserAction action,
        string dialogname,
        string[]? filternames,
        string[]? filters,
        string? start_path = null) {

        if (filternames != null) {
            assert (filternames.length == filters.length);
        }

        string button = "Error";

        switch (action) {
            case Gtk.FileChooserAction.OPEN:
                button = Gtk.Stock.OPEN;
                break;

            case Gtk.FileChooserAction.SAVE:
                button = Gtk.Stock.SAVE;
                break;

            case Gtk.FileChooserAction.SELECT_FOLDER:
                button = Gtk.Stock.APPLY;
                break;

            default :
                break;
        }

        var dialog = new Gtk.FileChooserDialog (
                        dialogname,
                        parent,
                        action,
                        Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                        button, Gtk.ResponseType.ACCEPT,
                        null
                    );

        if (filternames != null) {
            for (int i = 0; i < filternames.length; i++) {
                var fc = new Gtk.FileFilter();
                fc.set_filter_name (filternames[i]);
                fc.add_pattern (filters[i]);
                dialog.add_filter (fc);
            }
        }

        if (start_path != null) {
            var start = File.new_for_path (start_path);
            if (start.query_file_type (GLib.FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY) {
                Environment.set_current_dir (start_path);
                dialog.set_current_folder (start_path); //so Recently used folder not displayed
            }
        }

        //only need access to built-in puzzle directory if loading a .gno puzzle
        if (action == Gtk.FileChooserAction.OPEN && filters != null && filters[0] == "*.gno") {
             dialog.add_button (_("Built in puzzles"), Gtk.ResponseType.NONE);
        }

        int response;

        while (true) {
            response = dialog.run ();
            if (response == Gtk.ResponseType.NONE) {
                dialog.set_current_folder (get_app ().load_game_dir);
            } else {
                break;
            }
        }

        var filename = "";

        if (response == Gtk.ResponseType.ACCEPT) {
            Environment.set_current_dir (dialog.get_current_folder ());
            if (action == Gtk.FileChooserAction.SAVE) {
                filename = dialog.get_current_name ();
            } else {
                filename = dialog.get_filename ();
            }
        }

        dialog.destroy ();

        return filename;
    }

    public DataInputStream? open_data_input_stream (File file) {
        DataInputStream stream;
        if (!file.query_exists (null)) {
           stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
           return null;
        }

        try {
            stream = new DataInputStream (file.read (null));
        } catch (Error e) {
            Utils.show_warning_dialog (e.message);
            return null;
        }
        return stream;
    }
}
}
