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
/** Widget to hold variable number of clues, with either vertical or horizontal orientation **/
public class LabelBox : Gtk.Grid {
/** PUBLIC **/
    public Dimensions dimensions {
        private get {
            return _dimensions;
        }

        set {
            if (value != _dimensions) {
                _dimensions = value;
                resize (value);
            }
        }
    }

    public double fontheight {
        set {
           _fontheight = value.clamp (Gnonograms.MINFONTSIZE, Gnonograms.MAXFONTSIZE);

            for (uint index = 0; index < current_size; index++) {
                labels[index].fontheight = _fontheight;
            }
        }
    }

    public LabelBox (Gtk.Orientation orientation) {
        Object (column_homogeneous: true,
                row_homogeneous: true,
                column_spacing: 0,
                row_spacing: 0);

        vertical_labels = (orientation == Gtk.Orientation.HORIZONTAL);
        attach_position = vertical_labels ? Gtk.PositionType.RIGHT : Gtk.PositionType.BOTTOM;

        if (vertical_labels) {
            vexpand = true;
        } else {
            hexpand = true;
        }

        /* Must have at least one label for resize to work */
        var label = new_label (vertical_labels, other_size);
        attach (label, 0, 0, 1, 1);
        current_size = 1;
    }

    construct {
        labels = new Label[MAXSIZE];
    }

    public void highlight (uint index, bool is_highlight) {
        if (index >= size) {
            return;
        }

        labels[index].highlight (is_highlight);
    }

    public void unhighlight_all () {
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

    public string[] get_clues () {
        var texts = new string [current_size];

        for (uint index = 0; index < current_size; index++) {
            texts[index] = labels[index].clue;
        }

        return texts;
    }

    public void blank_labels () {
        for (uint index = 0; index < current_size; index++) {
            labels[index].clue = ("---");
        }
    }

/** PRIVATE **/
    /* Backing variables - do not assign directly */
    private Dimensions _dimensions;
    private double _fontheight;
    /* ----------------------------------------- */

    private Label[] labels;
    private bool vertical_labels; /* True if contains column labels */
    private uint size;
    private int current_size; /* Index of last added label */
    private uint other_size; /* Size of other label box */
    private Gtk.PositionType attach_position;

    private Label new_label (bool vertical, uint size) {
        var label = new Label (vertical);
        label.size = size;
        label.show_all ();

        labels[current_size] = label;
        current_size++;

        return label;
    }

    private void resize (Dimensions dimensions) {
        assert (current_size > 0);
        unhighlight_all();

        size = vertical_labels ? dimensions.width : dimensions.height;
        other_size = vertical_labels ? dimensions.height : dimensions.width;

        if (labels[0].size != other_size) {
            for (uint index = 0; index < current_size; index++) {
                labels[index].size = other_size;
            }
        }

        while (current_size < size) {
            var last_label = labels[current_size - 1];
            attach_next_to (new_label (vertical_labels, other_size),
                            last_label,
                            attach_position,
                            1, 1);
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
    }
}
}
