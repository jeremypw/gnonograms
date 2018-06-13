/* Holds all row or column clues for gnonograms
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
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */

namespace Gnonograms {
/** Widget to hold variable number of clues, with either vertical or horizontal orientation **/
public class LabelBox : Gtk.Grid {
/** PUBLIC **/
    public Gtk.PositionType attach_position { get; construct; }
    public bool vertical_labels { get; construct; } /* True if contains column labels */

    public Dimensions dimensions { get; set; }
    public int min_width { get; private set; }
    public int min_height { get; private set; }
    public double fontheight { get; set; }

    public LabelBox (Gtk.Orientation orientation) {
        Object (column_homogeneous: true,
                row_homogeneous: true,
                column_spacing: 0,
                row_spacing: 0,
                vertical_labels: (orientation == Gtk.Orientation.HORIZONTAL),
                attach_position: (orientation == Gtk.Orientation.HORIZONTAL) ? Gtk.PositionType.RIGHT : Gtk.PositionType.BOTTOM
                );
    }

    construct {
        labels = new Clue[MAXSIZE];
        size = 0;
        row_spacing = 0;
        column_spacing = 0;
        min_width = 0;
        min_height = 0;

        notify["fontheight"].connect (() => {
            for (uint index = 0; index < size; index++) {
                labels[index].fontheight = fontheight;
            }
            recalc_size ();
        });

        notify["dimensions"].connect (() => {
            resize (dimensions);
            recalc_size ();
        });
    }

    private void recalc_size () {
        if (size < 1) {
            return;
        }

        var r = dimensions.rows ();
        var c = dimensions.cols ();
        var cell = 2 * fontheight;

        /* Estimate maximum likely size required for random clues.
         * If this is exceeded then label will reduce its fontsize. */
        if (vertical_labels) {
            min_width = (int)(c * cell);
            min_height = (int)((r * Gnonograms.TYPICAL_MAX_BLOCKS_RATIO) * cell * Gnonograms.FONT_ASPECT_RATIO);
        } else {
            min_width = (int)((c * Gnonograms.TYPICAL_MAX_BLOCKS_RATIO) * cell / Gnonograms.FONT_ASPECT_RATIO);
            min_height = (int)(r * cell);
        }
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
            txt = _(BLANKLABELTEXT);
        }

        Clue? label = labels[index];
        if (label != null) {
            label.clue = txt;
        }
    }

    public void clear_formatting (uint index) {
        Clue? label = labels[index];

        if (label != null) {
            label.clear_formatting ();
        }
    }

    public void update_label_complete (uint index, Gee.List<Block> grid_blocks) {
        Clue? label = labels[index];

        if (label != null) {
            label.update_complete (grid_blocks);
        }
    }

/** PRIVATE **/
    private Clue[] labels;
    private int size;
    private int other_size; /* Size of other label box */

    private Clue new_label (bool vertical) {
        var label = new Clue (vertical);
        label.size = (int)(vertical_labels ? dimensions.height : dimensions.width);
        label.fontheight = _fontheight;
        label.show_all ();

        return label;
    }

    private void resize (Dimensions dimensions) {
        assert (size >= 0);
        unhighlight_all ();

        var new_size = (int)(vertical_labels ? dimensions.width : dimensions.height);
        var new_other_size = (int)(vertical_labels ? dimensions.height : dimensions.width);

        while (size < new_size) {
            var label = new_label (vertical_labels);
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

        for (uint index = 0; index < size; index++) {
            labels[index].size = other_size;
        }

        for (uint index = 0; index < size; index++) {
            labels[index].clue = ("0");
        }
    }

    public override void get_preferred_width (out int _min_width, out int _nat_width) {
        _min_width = min_width;
        _nat_width = min_width;
    }

    public override void get_preferred_height (out int _min_height, out int _nat_height) {
        _min_height = min_height;
        _nat_height = min_height;
    }
}
}
