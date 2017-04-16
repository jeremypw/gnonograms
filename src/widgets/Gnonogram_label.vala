/* Label class for Gnonograms3
 * Copyright (C) 2010-2011  Jeremy Wootten
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
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */

namespace Gnonograms {

class Label : Gtk.Label {
    private string attrib_start;
    private string displayed_text; /* text of clue in final form */
    private string _clue; /* text of clue in horizontal form */
    private int blockextent;

    private int _size;
    public int size { /* total number of cells in the row/column to which this label is attached */
        set {
            _size = value;
            update_tooltip ();
        }

        get {
            return _size;
        }
    }

    public bool is_column {get; construct;} /* true if clue for column */

    public double fontheight {
        set {
            var fontsize = (int)(1024 * (value));
            attrib_start = "<span size='%i' weight='bold'>".printf (fontsize);

            if (is_column) {
                set_size_request ((int)(value * 2), -1);
            } else {
                set_size_request (-1, (int)(value * 2));

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
            displayed_text = is_column ? vertical_string (_clue) : _clue;
            blockextent = Utils.blockextent_from_clue (_clue);
            update_markup ();
        }
    }

    construct {
        attrib_start = "<span>";
        size = -1;
    }

    public Label (string label_text, bool is_column) {
        Object (is_column: is_column,
                has_tooltip: true,
                use_markup: true);

        if (is_column) {
            set_alignment((float)0.5,(float)1.0);
        } else {
            set_alignment((float)1.0, (float)0.5);
        }

        if (label_text != "") {
            clue = label_text;
        }

        show_all ();
    }

    public void highlight (bool is_highlight) {
        if (is_highlight) {
            set_state(Gtk.StateType.SELECTED);
        } else {
            set_state(Gtk.StateType.NORMAL);
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
