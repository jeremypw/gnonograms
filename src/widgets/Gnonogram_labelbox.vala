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
    public Gtk.PositionType attach_position {get; construct;}
    public bool vertical_labels  {get; construct;} /* True if contains column labels */

    public Dimensions dimensions {
        set {
            if (value != _dimensions) {
                _dimensions = value;
                resize (value);
            }
        }
    }

    public double fontheight {
        set {
            var fh = value.clamp (Gnonograms.MINFONTSIZE, Gnonograms.MAXFONTSIZE);
            if (fh != _fontheight) {
                for (uint index = 0; index < size; index++) {
                    labels[index].fontheight = fh;
                }

                _fontheight = fh;
            }
        }
    }

    public LabelBox (Gtk.Orientation orientation) {
        Object (column_homogeneous: true,
                row_homogeneous: true,
                column_spacing: 0,
                row_spacing: 0,
                vertical_labels: (orientation == Gtk.Orientation.HORIZONTAL),
                attach_position: (orientation == Gtk.Orientation.HORIZONTAL) ? Gtk.PositionType.RIGHT : Gtk.PositionType.BOTTOM,
                vexpand: (orientation == Gtk.Orientation.HORIZONTAL),
                hexpand: !(orientation == Gtk.Orientation.HORIZONTAL)
                );
    }

    construct {
        labels = new Label[MAXSIZE];
        size = 0;
    }

    public void highlight (uint index, bool is_highlight) {
        if (index >= size) {
            return;
        }

        labels[index].highlight (is_highlight);
    }

    public void unhighlight_all () {
        for (uint index = 0; index < size; index++) {
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
        var texts = new string [size];

        for (uint index = 0; index < size; index++) {
            texts[index] = labels[index].clue;
        }

        return texts;
    }

    public void blank_labels () {
        for (uint index = 0; index < size; index++) {
            labels[index].clue = ("---");
        }
    }

/** PRIVATE **/
    /* Backing variables - do not assign directly */
    private Dimensions _dimensions;
    private double _fontheight;
    /* ----------------------------------------- */

    private Label[] labels;
    private int size;
    private int other_size; /* Size of other label box */

    private Label new_label (bool vertical, uint _other_size) {
        var label = new Label (vertical);
        label.size = _other_size;
        label.fontheight = _fontheight;
        label.show_all ();

        return label;
    }

    private void resize (Dimensions dimensions) {
        assert (size >= 0);
        unhighlight_all();

        var new_size = (int)(vertical_labels ? dimensions.width : dimensions.height);
        var new_other_size = (int)(vertical_labels ? dimensions.height : dimensions.width);

        if (new_other_size != other_size && size > 0) {
            for (uint index = 0; index < size; index++) {
                labels[index].size = new_other_size;
            }
        }

        while (size < new_size) {
            var label = new_label (vertical_labels, new_other_size);
            if (size > 0) {
                var last_label = labels[size - 1];
                attach_next_to (label, last_label, attach_position, 1, 1);
            } else {
                attach (label, 0, 0, 1, 1);
            }

            labels[size] = label;
            size++;
        }

        while (size > new_size) {
            if (vertical_labels) {
                remove_column (size - 1);
            } else {
                remove_row (size - 1);
            }
            /* No need to destroy unused labels */
            size--;
        }

        size = new_size;
        other_size = new_other_size;
    }
}
}
