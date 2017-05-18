/* Holds all row or column clues for gnonograms-elementary
 * Copyright (C) 2010 - 2017  Jeremy Wootten
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

public class LabelBox : Gtk.Grid {
    private Dimensions _dimensions;
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            if (value != _dimensions) {
                _dimensions = value;

                /* Do not update during construction */
                if (current_size > 0) {
                    resize ();
                }
            }
        }
    }

    private Label[] labels;
    private int current_size = 0;
    private bool vertical_labels; /* true if contains column labels */

    private uint size { /* no of labels in box */
        get {
            return vertical_labels ? dimensions.width : dimensions.height;
        }
    }

    private uint other_size { /* size of other label box */
        get {
            return vertical_labels ? dimensions.height : dimensions.width;
        }
    }

    private Gtk.PositionType attach_position {
        get {
            return vertical_labels ? Gtk.PositionType.RIGHT : Gtk.PositionType.BOTTOM;
        }
    }

    private double _fontheight;
    public double fontheight {
        get {
            return _fontheight;
        }

        set {
            _fontheight = value.clamp(Gnonograms.MINFONTSIZE, Gnonograms.MAXFONTSIZE);

            foreach (Gtk.Widget l in get_children ()) {
                ((Label)l).fontheight = _fontheight;
            }

            update_size_request ();
        }
    }


    construct {
        labels = new Label[MAXSIZE];
    }

    public LabelBox (Gtk.Orientation orientation, Dimensions dimensions) {
        Object (column_homogeneous: true,
                row_homogeneous: true,
                column_spacing: 0,
                row_spacing: 0);

        vertical_labels = (orientation == Gtk.Orientation.HORIZONTAL);
        this.dimensions = dimensions;

        /* Must have at least one label for resize to work */
        var label = new_label (vertical_labels, other_size);
        attach (label, 0, 0, 1, 1);
        if (vertical_labels) {
            vexpand = true;
        } else {
            hexpand = true;
        }
        resize ();
    }

    private Label new_label (bool vertical, uint size) {
        var label = new Label (vertical);
        label.size = size;
        label.fontheight = fontheight;
        labels[current_size] = label;
        current_size++;
        label.show_all ();
        return label;
    }

    private void resize () {
        assert (current_size > 0);
        unhighlight_all();

        if (labels[0].size != other_size) {
            update_label_size ();
        }

        while (current_size < size) {
            var last_label = labels[current_size - 1];
            attach_next_to (new_label (vertical_labels, other_size), last_label, attach_position, 1, 1);
        }

        while (current_size > size) {
            if (vertical_labels) {
                remove_column (current_size - 1);
            } else {
                remove_row (current_size - 1);
            }
            /* No need to destroy unused labels */
            current_size--;
        }

        update_size_request ();
        queue_draw ();
    }

    public void highlight (uint index, bool is_highlight) {
        if (index >= size) {
            return;
        }

        labels[index].highlight (is_highlight);
    }

    public void unhighlight_all() {
        for (uint index = 0; index < current_size; index++) {
            labels[index].highlight (false);
        }
    }

    public void update_label_text (uint index, string? txt) {
        if (txt == null) {
            txt = BLANKLABELTEXT;
        }

        labels[index].clue = txt;
    }

    public void update_label_size () {
        for (uint index = 0; index < current_size; index++) {
            labels[index].size = size;
        }
    }

    private void update_size_request () {
        if (vertical_labels) {
            set_size_request(-1, (int)(fontheight * other_size));
        } else {
            set_size_request((int)(fontheight * other_size * 0.75), -1);
        }


    }

//~     public string to_string() {
//~         StringBuilder sb = new StringBuilder();

//~         for (uint index = 0; index < current_size; index++) {
//~             sb.append (labels[index].label);
//~             sb.append ("\n");
//~         }

//~         return sb.str;
//~     }

    public string[] get_clues () {
        var texts = new string [current_size];
        for (uint index = 0; index < current_size; index++) {
            texts[index] = labels[index].clue;
        }

        return texts;
    }

    public void blank_labels () {
        set_all_to_string ("---");
    }

    private void set_all_to_string (string txt) {
        for (uint index = 0; index < current_size; index++) {
            labels[index].clue = txt;
        }
    }
}
}
