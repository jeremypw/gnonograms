/* Displays clues for gnonograms-elementary
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

class Label : Gtk.Label {
    private string attrib_start;
    private string displayed_text; /* text of clue in final form */
    private string _clue; /* text of clue in horizontal form */
    private int blockextent;

    private uint _size;
    public uint size { /* total number of cells in the row/column to which this label is attached */
        set {
            _size = value;
            update_tooltip ();
        }

        get {
            return _size;
        }
    }

    public bool vertical_text { get; set; } /* true if clue for column */

    public double fontheight {
        set {
            var fontsize = (int)(1024 * (value));
            attrib_start = "<span size='%i' weight='bold'>".printf (fontsize);

            /* Ensure grid remains square */
            if (vertical_text) {
                set_size_request (int.max((int)(value * 2), 24), -1);
            } else {
                set_size_request (-1, int.max((int)(value * 2), 24));
            }

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


            blockextent = Utils.blockextent_from_clue (_clue);

            if (!vertical_text) {
                displayed_text += " ";
            }

            update_markup ();
        }
    }

    construct {
        attrib_start = "<span>";
        size = 0;
    }

    public Label (bool vertical_text, string label_text = "") {
        Object (vertical_text: vertical_text,
                has_tooltip: true,
                use_markup: true);

        if (vertical_text) {
            set_alignment((float)0.5,(float)1.0);
        } else {
            set_alignment((float)1.0, (float)0.5);
        }

        if (label_text != "") {
            clue = label_text;
        } else {
            clue = "?,?,?";
        }
    }

    public void highlight (bool is_highlight) {
        if (is_highlight) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
    }

    private void update_markup () {
        var markup = attrib_start + displayed_text + "</span>";
        set_markup (markup);
        update_tooltip ();
    }

    private void update_tooltip () {
        var freedom = size - blockextent;
        if (freedom >= 0) {
            has_tooltip = true;
            set_tooltip_markup (attrib_start + _("Freedom = %i").printf(freedom) + "</span>");
        } else {
            has_tooltip = false;
        }
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
