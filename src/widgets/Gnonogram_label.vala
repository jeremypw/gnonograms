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

class Label : Gtk.Label {
/** PUBLIC **/
    public bool vertical_text { get; construct; }

    public uint size { /* total number of cells in the row/column to which this label is attached */
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
            displayed_text = vertical_text ? vertical_string (_clue) : _clue;

            if (!vertical_text) {
                displayed_text += " ";
            }

            update_markup ();
        }
    }

    public Label (bool _vertical_text, string label_text = "") {
        Object (has_tooltip: true,
                use_markup: true,
                vertical_text: _vertical_text,
                xalign: _vertical_text ? (float)0.5 : (float)1.0,
                yalign: _vertical_text ? (float)1.0 : (float)0.5,
                size: 0
                );

        if (label_text != "") {
            clue = label_text;
        } else {
            clue = "?,?,?";
        }

        size_allocate.connect (() => {
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

/** PRIVATE **/
    private const string attr_template = "<span size='%i' weight='bold'>";
    private double fontsize;
    private string displayed_text; /* text of clue in final form */
    private string _clue; /* text of clue in horizontal form */
    private uint _size;

    private void update_markup (double fs = fontsize) {
        set_markup (attr_template.printf ((int)fs) + displayed_text + "</span>");
        var layout = get_layout ();
        int w, h;
        layout.get_size (out w, out h);
        var size = vertical_text ? h : w;
        var alloc = vertical_text ? get_allocated_height () : get_allocated_width ();

        if (size / 1024 > alloc) {
            update_markup (fs * 0.95);
        } else {
            update_tooltip ();
        }
    }

    private void update_tooltip () {
        set_tooltip_markup (attr_template.printf ((int)fontsize) +
                            _("Freedom = %u").printf (size - Utils.blockextent_from_clue (_clue)) +
                            "</span>");
    }

    private string vertical_string (string s) {
        string[] sa = s.split_set (", ");
        StringBuilder sb = new StringBuilder ("");

        foreach (string ss in sa) {
            if (ss != "") {
              sb.append (ss);
              sb.append ("\n");
            }
        }

        sb.truncate (sb.len - 1);

        return sb.str;
    }
}
}
