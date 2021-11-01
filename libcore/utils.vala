/* Utility functions for gnonograms
 * Copyright (C) 2010-2021  Jeremy Wootten
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
 *  Author: Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms.Utils {
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
            return { 0 };
        } else {
            int[] block_array = new int[blocks.length];
            int index = 0;

            foreach (string block in blocks) {
                block_array[index++] = int.parse (block);
            }

            return block_array;
        }
    }

    public Gee.ArrayList<Block> block_struct_array_from_clue (string s) {
        string[] blocks = remove_blank_lines (s.split_set (", "));
        var block_array = new Gee.ArrayList<Block> ();
        foreach (string block in blocks) {
            block_array.add (new Block (int.parse (block), false, false));
        }

        return block_array;
    }

    public int blockextent_from_clue (string? s) {
        if (s == null) {
            return 0;
        }

        int[] blocks = block_array_from_clue (s);
        int extent = 0;

        foreach (int block in blocks) {
            extent += block + 1;
        }

        extent--;
        return extent;
    }

    public int freedom_from_array (CellState[] arr) {
        var filled = 0; // count of filled cells
        var blocks = 0; // count of filled blocks
        int length = arr.length;

        for (int i = 0; i < length; i++) {
            if (arr[i] == CellState.FILLED) {
                filled++;
                if (i == 0 || arr[i - 1] == CellState.EMPTY) {
                    blocks++;
                }
            }
        }

        return (length - filled - (blocks - 1));
    }

    public string[] row_clues_from_2D_array (My2DCellArray array) { //vala-lint=naming-convention
        var rows = array.rows;
        var cols = array.cols;
        var clues = new string[rows];
        for (int r = 0; r < rows; r++) {
            clues[r] = array.data2text (r, cols, false);
        }

        return clues;
    }

    public string[] col_clues_from_2D_array (My2DCellArray array) { //vala-lint=naming-convention
        var rows = array.rows;
        var cols = array.cols;
        var clues = new string[cols];

        for (int c = 0; c < cols; c++) {
            clues[c] = array.data2text (c, rows, true);
        }

        return clues;
    }

    public Gee.ArrayList<Block> complete_block_array_from_cellstate_array (CellState[] cellstates) {
        var blocks = new Gee.ArrayList<Block> ();
        var previous_state = CellState.UNKNOWN;
        int count = 0;
        bool valid = true;
        foreach (CellState state in cellstates) {
            switch (state) {
                case CellState.EMPTY:
                    if (count > 0) {
                        blocks.add (new Block (count, true, false));
                        count = 0;
                    } else {
                        valid = true;
                    }

                    break;
                case CellState.FILLED:
                    if (valid) {
                        count++;
                    }

                    break;
                case CellState.UNKNOWN:
                    if (valid || previous_state != CellState.UNKNOWN) {
                        valid = false;
                        count = 0;
                        blocks.add (new Block.null ());
                    }

                    break;
                default: /* Can occur when dragging beyond grid */
                    break;
            }

            previous_state = state;
        }

        if (count > 0) {
            blocks.add (new Block (count, true, false));
        }

        return blocks;
    }

    public string block_string_from_cellstate_array (CellState[] cellstates) {
        StringBuilder sb = new StringBuilder ("");
        CellState count_state = CellState.UNDEFINED;
        int count = 0, blocks = 0;
        bool counting = false;
        foreach (var state in cellstates) {
            switch (state) {
                case CellState.EMPTY:
                    if (count_state == CellState.FILLED) {
                        sb.append (count.to_string () + BLOCKSEPARATOR);
                        blocks++;
                    } else if (count_state == CellState.UNKNOWN) {
                        sb.append ("?" + BLOCKSEPARATOR);

                    }

                    counting = false;
                    count_state = CellState.UNDEFINED;
                    count = 0;

                    break;
                case CellState.FILLED:
                    if (count_state == CellState.UNDEFINED) {
                        count = 0;
                        counting = true;
                    } else if (count_state == CellState.UNKNOWN) {
                        sb.append ("?" + BLOCKSEPARATOR);
                        count = 0;
                    }

                    count_state = CellState.FILLED;
                    count++;

                    break;
                case CellState.UNKNOWN:
                    if (count_state == CellState.UNDEFINED) {
                        counting = true;
                    } else if (count_state == CellState.FILLED) {
                        sb.append (count.to_string () + BLOCKSEPARATOR);
                        count = 0;
                    }

                    count_state = CellState.UNKNOWN;

                    break;
                default:
                    return _(BLANKLABELTEXT);
            }
        }

        if (count_state == CellState.FILLED) {
            sb.append (count.to_string () + BLOCKSEPARATOR);
            blocks++;
        } else if (count_state == CellState.UNKNOWN) {
            sb.append ("?" + BLOCKSEPARATOR);
            blocks++;
        } if (blocks == 0) {
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
        StringBuilder sb = new StringBuilder ();
        foreach (uint state in cs) {
            sb.append (state.to_string ());
            sb.append (" ");
        }

        return sb.str;
    }

    public static int show_dlg (string primary_text,
                                Gtk.MessageType type,
                                string? secondary_text,
                                Gtk.Window? parent) {

        string icon_name = "";
        var buttons = Gtk.ButtonsType.CLOSE;
        switch (type) {
            case Gtk.MessageType.INFO:
                icon_name = "dialog-information";

                break;
            case Gtk.MessageType.WARNING:
                icon_name = "dialog-warning";

                break;
            case Gtk.MessageType.ERROR:
                icon_name = "dialog-error";

                break;
            case Gtk.MessageType.QUESTION:
                icon_name = "dialog-question";
                buttons = Gtk.ButtonsType.NONE;

                break;
            default:
                assert_not_reached ();
        }

        var dialog = new Granite.MessageDialog.with_image_from_icon_name (primary_text,
                                                                          secondary_text ?? "",
                                                                          icon_name, buttons);

        dialog.set_transient_for (parent);
        if (type == Gtk.MessageType.QUESTION) {
            dialog.add_button ("YES", Gtk.ResponseType.YES);
            dialog.add_button ("NO", Gtk.ResponseType.NO);
            dialog.set_default_response (Gtk.ResponseType.NO);
        }

        dialog.set_position (Gtk.WindowPosition.MOUSE);
        int response = dialog.run ();
        dialog.destroy ();
        return response;
    }

    public static void show_error_dialog (string primary_text,
                                          string? secondary_text = null,
                                          Gtk.Window? parent = null) {

        show_dlg (primary_text, Gtk.MessageType.ERROR, secondary_text, parent);
    }

    public static bool show_confirm_dialog (string primary_text,
                                            string? secondary_text = null,
                                            Gtk.Window? parent = null) {

        var response = show_dlg (
            primary_text,
            Gtk.MessageType.QUESTION,
            secondary_text,
            parent);

        return response == Gtk.ResponseType.YES;
    }

    /** The @action parameter also indicates the default setting for saving the solution.
      * The user selected option is returned in @save_solution.
     **/
    public static string? get_open_save_path (Gtk.Window? parent,
                                             string dialogname,
                                             bool save,
                                             string start_path,
                                             string basename) {

        string? file_path = null;
        string button_label = save ? _("Save") : _("Open");
        var gtk_action = save ? Gtk.FileChooserAction.SAVE : Gtk.FileChooserAction.OPEN;
        var dialog = new Gtk.FileChooserNative (
            dialogname,
            parent,
            gtk_action,
            button_label,
            _("Cancel")
        );

        dialog.set_modal (true);
        dialog.set_filename (Path.build_path (Path.DIR_SEPARATOR_S, start_path, basename));
        if (save) {
            dialog.set_current_name (basename);
        }

        var response = dialog.run ();
        if (response == Gtk.ResponseType.ACCEPT) {
            file_path = dialog.get_filename ();
        }

        dialog.destroy ();

        return file_path;
    }

    public Gdk.Rectangle get_monitor_area (Gdk.Screen screen, Gdk.Window window) {
        var display = Gdk.Display.get_default ();
        var monitor = display.get_monitor_at_window (window);
        return monitor.get_geometry ();
    }
}
