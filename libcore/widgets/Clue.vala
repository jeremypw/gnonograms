/* Label.vala
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

class Gnonograms.Clue : Object {
    public Gtk.Label label { get; construct; }
    public unowned ClueBox cluebox { get; construct; }

    private string _text; /* text of clue in horizontal form */
    public string text {
        get {
            return _text;
        }

        set {
            _text = value;
            clue_blocks = Utils.block_struct_array_from_clue (value);
            update_markup ();
        }
    }

    public bool vertical_text { get; construct; }

    private Gee.List<Block> clue_blocks; // List of blocks based on clue

    public Clue (bool _vertical_text, ClueBox cluebox) {
        Object (
            vertical_text: _vertical_text,
            cluebox: cluebox
        );
    }

    construct {
        label = new Gtk.Label ("") {
            xalign = _vertical_text ? (float)0.5 : (float)1.0,
            yalign = vertical_text ? (float)1.0 : (float)0.5,
            has_tooltip = true,
            use_markup = true
        };

        text = "0";

        label.realize.connect_after (update_markup);
        cluebox.notify["n_cells"].connect (update_tooltip);
        cluebox.notify["font-size"].connect (update_markup);
    }

    public void highlight (bool is_highlight) {
        if (is_highlight) {
            label.add_css_class (Granite.STYLE_CLASS_ACCENT);
        } else {
            label.remove_css_class (Granite.STYLE_CLASS_ACCENT);
        }
    }

    public void clear_formatting () {
        label.remove_css_class ("warn");
        label.remove_css_class ("dim");
    }

    public void update_complete (Gee.List<Block> grid_blocks) {
        foreach (Block block in clue_blocks) {
            block.is_complete = false;
            block.is_error = false;
        }

        label.remove_css_class ("warn");
        label.remove_css_class ("dim");

        uint complete = 0;
        uint errors = 0;
        uint grid_complete = 0;
        uint grid_null = 0;

        foreach (Block b in grid_blocks) {
            if (b.is_complete) {
                grid_complete++;
            } else if (b.is_null ()) {
                grid_null++;
            }
        }

        if (!grid_blocks.is_empty) {
            int clue_index = 0;
            int grid_index = 0;
            while (grid_index < grid_blocks.size) {
                var block = grid_blocks.@get (grid_index);
                if (block.is_null ()) {
                    break;
                } else {
                    if (clue_index < clue_blocks.size) {
                        var clue_block = clue_blocks.@get (clue_index);
                        if (clue_block.length == block.length) {
                            clue_block.is_complete = true;
                            block.is_complete = false; /* mark as matched */
                            complete++;
                            clue_block.is_error = false;
                        } else {
                            clue_block.is_complete = false;
                            clue_block.is_error = true;
                            errors++;
                        }
                    } else {
                        errors++;
                        break;
                    }
                }

                clue_index++;
                grid_index++;
            }

            if (errors > 0) {
                label.add_css_class ("warn");
            }

            if (complete == clue_blocks.size && errors == 0 && grid_null == 0) {
                update_markup ();
                label.add_css_class ("dim");
                return;
            }

            if (grid_index >= grid_blocks.size) {
                update_markup ();
                return;
            }

            clue_index = clue_blocks.size - 1;
            grid_index = grid_blocks.size - 1;

            while (grid_index >= 0) {
                var block = grid_blocks.@get (grid_index);
                if (block.is_null ()) {
                    break;
                } else {
                    if (clue_index >= 0) {
                        var clue_block = clue_blocks.@get (clue_index);
                        if (clue_block.is_complete || clue_block.is_error) {
                            break;
                        }

                        if (clue_block.length == block.length) {
                            clue_block.is_complete = true;
                            block.is_complete = false; /* mark as matched */
                            complete++;
                        } else {
                            clue_block.is_complete = false;
                            clue_block.is_error = true;
                            errors++;
                        }
                    } else {
                        errors++;
                        break;
                    }
                }

                clue_index--;
                grid_index--;
            }

            /* Make sure any unmatched complete grid blocks could be correct */
            if (grid_complete > complete) {
                foreach (Block b in grid_blocks) {
                    if (b.is_complete && !b.is_null ()) {
                        bool found = false;
                        var len = b.length;
                        foreach (Block cb in clue_blocks) {
                            if (!cb.is_complete && cb.length == len) {
                                found = true;
                            }
                        }

                        if (!found) {
                            errors++;
                        }
                    }
                }
            }
        } else if (text != "0") { /* Zero grid blocks should only occur if cellstates all "empty" */
            errors++;
        }

        if (errors > 0) {
            label.add_css_class ("warn");
        }

        update_markup ();
    }

    private void update_markup () {
        label.set_markup ("<span font='%i'>".printf (cluebox.font_size) + get_markup () + "</span>");
        update_tooltip ();
    }

    private void update_tooltip () {
        label.set_tooltip_markup ("<span font='%i'>".printf (cluebox.font_size) +
            _("Freedom = %u").printf (cluebox.n_cells - Utils.blockextent_from_clue (_text)) +
            "</span>"
        );
    }

    private string get_markup () {
        string attrib = "";
        string weight = "bold";
        string strikethrough = "false";
        bool warn = label.has_css_class ("warn");
        StringBuilder sb = new StringBuilder ("");

        foreach (Block clue_block in clue_blocks) {
            strikethrough = "false";
            if (warn) {
                weight = "normal";
            } else if (clue_block.is_complete) {
                strikethrough = "true";
                weight = "light";
            } else {
                weight = "bold";
            }

            attrib = "<span weight='%s' strikethrough='%s'>".printf (weight, strikethrough);
            sb.append (attrib);
            sb.append (clue_block.length.to_string ());
            sb.append ("</span>");
            if (vertical_text) {
                sb.append ("\n");
            } else {
                sb.append (", ");
            }
        }

        if (vertical_text) {
            sb.truncate (sb.len - 1);
        } else {
            sb.truncate (sb.len - 2);
        }

        return sb.str;
    }
}
