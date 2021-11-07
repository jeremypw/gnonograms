/* Labelbox.vala
 * Copyright (C) 2010 - 2021  Jeremy Wootten
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

public class Gnonograms.LabelBox : Gtk.Grid {
    public Dimensions dimensions { set {
        n_labels = orientation == Gtk.Orientation.HORIZONTAL ? value.cols () : value.rows();
        n_cells = orientation == Gtk.Orientation.HORIZONTAL ? value.rows () : value.cols ();
        resize ();
    } }

    public int cell_size { get; set; }

    private uint n_labels = 0;
    private uint n_cells = 0;

    public LabelBox (Gtk.Orientation _orientation) {
        Object (column_homogeneous: true,
                row_homogeneous: true,
                column_spacing: 0,
                row_spacing: 0,
                orientation: _orientation,
                expand: false
        );
    }

    construct {
        row_spacing = 0;
        column_spacing = 0;

        notify["cell-size"].connect (() => {
            var width = orientation == Gtk.Orientation.HORIZONTAL ? (int)n_labels * cell_size : -1;
            var height = orientation == Gtk.Orientation.HORIZONTAL ? -1 : (int)n_labels * cell_size;
            get_children ().foreach ((w) => {
                ((Gnonograms.Clue)w).cell_size = cell_size;
            });
            set_size_request (width, height);
        });

        show_all ();
    }

    private Gnonograms.Clue? get_label (uint index) {
        var n_children = get_children ().length ();
        if (index >= n_children) {
            return null;
        } else {
            return (Gnonograms.Clue)(get_children ().nth_data (n_children - index - 1));
        }
    }

    public void highlight (uint index, bool is_highlight) {
        var label = get_label (index);
        if (label != null) {
            label.highlight (is_highlight);
        }
    }

    public void unhighlight_all () {
        get_children ().foreach ((w) => {
            ((Gnonograms.Clue)w).highlight (false);
        });
    }

    public void update_label_text (uint index, string? txt) {
        var label = get_label (index);
        if (label != null) {
            label.clue = txt ?? _(BLANKLABELTEXT);
        }
    }

    public void clear_formatting (uint index) {
        var label = get_label (index);
        if (label != null) {
            label.clear_formatting ();
        }
    }

    public void update_label_complete (uint index, Gee.List<Block> grid_blocks) {
        var label = get_label (index);
        if (label != null) {
            label.update_complete (grid_blocks);
        }
    }

    private void resize () {
        foreach (var child in get_children ()) {
            child.destroy ();
        }

        for (var i = 0; i < n_labels; i++) {
            var label = new Clue (orientation == Gtk.Orientation.HORIZONTAL) {
                n_cells = this.n_cells,
                cell_size = this.cell_size
            };

            add (label);
        }

        show_all ();
    }
}
