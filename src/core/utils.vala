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
 *  Jeremy Wootten <jeremywootten@gmail.com>
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
        string[] blocks = remove_blank_lines (s.split_set (", "));

        if (blocks.length == 0) {
            return {0};
        } else {
            int[] block_array = new int[blocks.length];
            int index = 0;

            foreach (string block in blocks) {
                block_array[index++] = int.parse (block);
            }

            return block_array;
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

    public int freedom_from_array (CellState[] arr, out int filled, out int blocks) {
        filled = 0; // count of filled cells
        blocks = 0; // count of filled blocks
        int length = arr.length;

        for (int i = 0; i < length; i++) {
            if (arr[i] == CellState.FILLED) {
                filled++;

                if (i == 0 || arr[i - 1] == CellState.EMPTY) {
                    blocks++;
                }
            }
        }

        return (length - filled - blocks + 1);
    }

    public string[] row_clues_from_2D_array (My2DCellArray array) {
        var rows = array.rows;
        var cols = array.cols;
        var clues = new string[rows];

        for (int r = 0; r < rows; r++) {
            clues[r] = array.data2text (r, cols, false);
        }

        return clues;
    }
    public string[] col_clues_from_2D_array (My2DCellArray array) {
        var rows = array.rows;
        var cols = array.cols;
        var clues = new string[cols];

        for (int c = 0; c < cols; c++) {
            clues[c] = array.data2text (c, rows, true);
        }

        return clues;
    }

    public string block_string_from_cellstate_array (CellState[] cellstates) {
        StringBuilder sb = new StringBuilder ("");
        int count = 0, blocks = 0;
        bool counting = false;

        foreach (var state in cellstates) {
            switch (state) {
                case CellState.EMPTY:
                    if (counting) {
                        sb.append (count.to_string() + BLOCKSEPARATOR);
                        counting = false;
                        count = 0;
                        blocks++;
                    }

                    break;

                case CellState.FILLED:
                    counting = true;
                    count++;

                    break;

                default:
                    return BLANKLABELTEXT;
            }
        }

        if (counting) {
            sb.append (count.to_string ());
            blocks++;
        } else if (blocks == 0) {
            sb.append ("0");
        } else {
            sb.truncate (sb.len - BLOCKSEPARATOR.length); // remove trailing seperator
        }

        return sb.str;
    }

    public CellState[] cellstate_array_from_string (string s) {
        CellState[] cs = {};
        string[] blocks = remove_blank_lines (s.split_set (BLOCKSEPARATOR));

        foreach (var block in blocks) {
            cs += (CellState)(int.parse (block)).clamp (0, CellState.UNDEFINED);
        }

        return cs;
    }

    public string string_from_cellstate_array (CellState[] cs) {
        StringBuilder sb = new StringBuilder();

        foreach (uint state in cs) {
            sb.append (state.to_string ());
            sb.append (" ");
        }

        return sb.str;
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

    /** The @action parameter also indicates the default setting for saving the solution.
      * The user selected option is returned in @save_solution.
     **/
    public static string? get_file_path (Gtk.Window? parent,
                                          Gnonograms.FileChooserAction action,
                                          string dialogname,
                                          FilterInfo [] filters,
                                          string? start_path,
                                          out bool save_solution) {

        string? file_path = null;

        save_solution = (action == Gnonograms.FileChooserAction.SAVE_WITH_SOLUTION);

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

            foreach (var info in filters) {
                var fc = new Gtk.FileFilter();
                fc.set_filter_name (info.name);
                fc.add_pattern (info.pattern);
                dialog.add_filter (fc);
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

    public int grade_to_minimum_passes (uint grd, Dimensions dimensions) {
        var avg_length = (double)(dimensions.rows () + dimensions.cols ()) / 10.0 * (double)grd + 4.0;

        if (grd <= Difficulty.ADVANCED) {
            return (int)(avg_length);
        } else {
            return (int)(grd - (Difficulty.ADVANCED)) * 100;
        }

    }

    public Difficulty passes_to_grade (uint passes, Dimensions dimensions, bool unique_only, bool advanced) {
        var diff = Difficulty.UNDEFINED;
        if (passes < 1) {
            return diff;
        }

        var cells_per_pass = (double)(dimensions.length ()) / ((double)passes - 2);

        if (cells_per_pass < 1 ) {
            diff = Difficulty.ADVANCED;
        } else if (cells_per_pass < 2 ) {
            diff = Difficulty.CHALLENGING;
        }
        else if (cells_per_pass < 4 ) {
            diff = Difficulty.HARD;
        }
        else if (cells_per_pass < 6 ) {
            diff = Difficulty.MODERATE;
        }
        else {
            diff = Difficulty.EASY;
        }

        if (!advanced && diff > Difficulty.CHALLENGING) {
            diff = Difficulty.CHALLENGING;
        } else if (unique_only && diff > Difficulty.ADVANCED) { // Cannot be "POSSIBLY AMBIGUOUS"
            diff = Difficulty.ADVANCED;
        }

        return diff;
    }

    public string passes_to_grade_description (uint passes, Dimensions dimensions, bool unique_only, bool advanced) {
        var diff = passes_to_grade (passes, dimensions, unique_only, advanced);
        return Gnonograms.difficulty_to_string (diff);
    }
}
}
