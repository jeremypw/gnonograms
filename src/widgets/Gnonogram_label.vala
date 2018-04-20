/* Displays clues for gnonograms
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

class Clue : Gtk.Label {

/** PUBLIC **/
    public bool vertical_text { get; construct; }

    /* total number of cells in the row/column to which this label is attached
       Used to calculate freedom */

    public uint size {
        set {
            _size = value;
            update_tooltip ();
        }

        private get {
            return _size;
        }
    }

    public double fontheight {
        set {
            fontsize = (int)(1024 * (value));
            update_markup ();
        }
    }

    public string clue {
        get {
            return _clue;
        }

        set {
            _clue = value;
            clue_blocks = Utils.block_struct_array_from_clue (value);
            update_markup ();
        }
    }

    construct {
        clue = "0";
        has_tooltip = true;
        use_markup = true;
    }

    public Clue (bool _vertical_text) {
        Object (
                vertical_text: _vertical_text,
                xalign: _vertical_text ? (float)0.5 : (float)1.0,
                yalign: _vertical_text ? (float)1.0 : (float)0.5
                );



        size_allocate.connect_after (() => {
            update_markup ();
        });

        realize.connect_after (() => {
            update_markup ();
        });
    }

    public void highlight (bool is_highlight) {
        if (is_highlight) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
    }

    public void update_complete (Gee.List<Block> _grid_blocks) {
        grid_blocks = _grid_blocks;
        foreach (Block block in clue_blocks) {
            block.is_complete = false;
            block.is_error = false;
        }

        var sc = get_style_context ();
        sc.remove_class ("warn");
        sc.remove_class ("dim");

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
                sc.add_class ("warn");
            }

            if (complete == clue_blocks.size && errors == 0 && grid_null == 0) {
                update_markup ();
                sc.add_class ("dim");
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
        } else if (clue != "0") { /* Zero grid blocks should only occur if cellstates all "empty" */
            errors++;
        }

        if (errors > 0) {
            sc.add_class ("warn");
        }

        update_markup ();
    }

/** PRIVATE **/
    private Gee.List<Block> clue_blocks;
    private Gee.List<Block> grid_blocks;
    private const string attr_template = "<span size='%i' weight='%s' strikethrough='%s'>";
    private const string tip_template = "<span size='%i'>";
    private double fontsize;
    private string _clue; /* text of clue in horizontal form */
    private uint _size;

    private void update_markup (double fs = fontsize) {
        var alloc = vertical_text ? get_allocated_height () : get_allocated_width ();
        if (!get_realized () || alloc < 10 || fontsize < 1000) {
            return;
        }

        string markup = "<span size='%i'>".printf ((int)fs) + get_markup () + "</span>";
        set_markup (markup);

        var layout = get_layout ();
        int w, h;
        layout.get_size (out w, out h);
        var size = (int)((vertical_text ? h : w) / 1024);

        if (size - alloc > 6) {
            update_markup (fs * 0.9);
        } else {

            update_tooltip ();
        }
    }

    private void update_tooltip () {
        set_tooltip_markup (tip_template.printf ((int)fontsize / 2) +
                            _("Freedom = %u").printf (size - Utils.blockextent_from_clue (_clue)) +
                            "</span>");
    }

    private string get_markup () {
        string attrib = "";
        string weight = "bold";
        string strikethrough = "false";
        bool warn = get_style_context ().has_class ("warn");
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
}
