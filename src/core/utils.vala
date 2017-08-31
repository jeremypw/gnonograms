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
        return show_dlg (msg, Gtk.MessageType.WARNING, Gtk.ButtonsType.YES_NO, parent) == Gtk.ResponseType.YES;
    }

    public static string? get_file_path (Gtk.Window? parent,
                                          Gnonograms.FileChooserAction action,
                                          string dialogname,
                                          string[]? filternames,
                                          string[]? filters,
                                          string? start_path,
                                          out bool save_solution) {

        string? file_path = null;

        save_solution = (action == Gnonograms.FileChooserAction.SAVE_WITH_SOLUTION);

        if (filternames != null) {
            assert (filternames.length == filters.length);
        }

        string button = "Error";
        Gtk.FileChooserAction gtk_action = Gtk.FileChooserAction.SAVE;

        switch (action) {
            case Gnonograms.FileChooserAction.OPEN:
                gtk_action = Gtk.FileChooserAction.OPEN;
                button = Gtk.Stock.OPEN;
                break;

            case Gnonograms.FileChooserAction.SAVE_WITH_SOLUTION:
            case Gnonograms.FileChooserAction.SAVE_NO_SOLUTION:
                gtk_action = Gtk.FileChooserAction.SAVE;
                button = Gtk.Stock.SAVE;
                break;

            case Gnonograms.FileChooserAction.SELECT_FOLDER:
                gtk_action = Gtk.FileChooserAction.SELECT_FOLDER;
                button = Gtk.Stock.APPLY;
                break;

            default :
                break;
        }

        var dialog = new Gtk.FileChooserDialog (
                        dialogname,
                        parent,
                        gtk_action,
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

        dialog.local_only = false;

        //only need access to built-in puzzle directory if loading a .gno puzzle
        if (action == Gnonograms.FileChooserAction.OPEN) {
             dialog.add_button (_("Built in puzzles"), Gtk.ResponseType.APPLY);
        } else {
            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.HORIZONTAL;
            grid.column_spacing = 6;

            var save_solution_switch = new Gtk.Switch ();
            save_solution_switch.state = save_solution;

            var save_solution_label = new Gtk.Label (_("Save solution too"));

            grid.add (save_solution_label);
            grid.add (save_solution_switch);

            dialog.add_action_widget (grid, Gtk.ResponseType.NONE);

            grid.show_all ();
        }

        File start;
        if (start_path != null) {
            start = File.new_for_commandline_arg (start_path);
        } else {
            start = File.new_for_commandline_arg (get_app ().load_game_dir);
        }

        dialog.set_current_folder (start.get_path ());

        var response = run_dialog (dialog);

        if (response == Gtk.ResponseType.ACCEPT) {
            if (gtk_action == Gtk.FileChooserAction.SAVE) {
                file_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                             dialog.get_current_folder (),
                                             dialog.get_current_name ()
                            );
            } else {
                file_path = dialog.get_filename ();
            }
        }

        dialog.destroy ();

        return file_path;
    }

    private int run_dialog (Gtk.FileChooserDialog dialog) {
        int response;

        while (true) {
            response = dialog.run ();

            switch (response) {
                case Gtk.ResponseType.APPLY:
                    dialog.set_current_folder (get_app ().load_game_dir);
                    break;

                case Gtk.ResponseType.NONE:
                    break;

                default:
                    return response;
            }
        }


    }

    public int grade_to_passes (uint grd) {
        if (grd <= Difficulty.ADVANCED) {
            return ((int)grd + 1) * 2;
        } else {
            return (int)(grd - (Difficulty.ADVANCED)) * 100;
        }

    }

    public Difficulty passes_to_grade (uint passes) {
        if (passes >= 50) {
            return Difficulty.ADVANCED;
        } else {
            return (Difficulty)(passes / 2 - 1);
        }
    }

    public string passes_to_grade_description (uint passes) {
        return difficulty_to_string (passes_to_grade (passes));
    }
}
}
