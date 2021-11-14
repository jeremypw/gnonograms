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
    public View view { get; construct; }

    private uint n_labels = 0;
    private uint n_cells = 0;

    public LabelBox (Gtk.Orientation _orientation, View view) {
        Object (view: view,
                column_homogeneous: true,
                row_homogeneous: true,
                column_spacing: 0,
                row_spacing: 0,
                orientation: _orientation,
                expand: false
        );
    }

    construct {
        view.notify["cell-size"].connect (() => {
            get_children ().foreach ((w) => {
                ((Gnonograms.Clue)w).cell_size = view.cell_size;
            });

            set_size ();
        });

        view.controller.notify ["dimensions"].connect (() => {
            var new_n_labels = orientation == Gtk.Orientation.HORIZONTAL ?
                                              view.controller.dimensions.width :
                                              view.controller.dimensions.height;

            var new_n_cells = orientation == Gtk.Orientation.HORIZONTAL ?
                                             view.controller.dimensions.height :
                                             view.controller.dimensions.width;

            if (new_n_labels != n_labels || new_n_cells != n_cells) {
                n_labels = new_n_labels;
                n_cells = new_n_cells;
                change_n_labels ();
            }
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

    public string[] get_clues () {
        string[] clues = new string [n_labels];
        var index = n_labels;
        foreach (var widget in get_children ()) { // Delivers widgets in reverse order they were added
            index--;
            clues[index] = ((Clue)widget).clue;
        }

        return clues;
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

    private void change_n_labels () {
        foreach (var child in get_children ()) {
            child.destroy ();
        }

        for (var i = 0; i < n_labels; i++) {
            var label = new Clue (orientation == Gtk.Orientation.HORIZONTAL) {
                n_cells = this.n_cells,
                cell_size = view.cell_size
            };

            add (label);
        }

        set_size ();
        show_all ();
    }

    private void set_size () {
        int width = (int)(orientation == Gtk.Orientation.HORIZONTAL ?
            n_labels * view.cell_size :
            n_cells * view.cell_size * GRID_LABELBOX_RATIO
        );

        int height = (int)(orientation == Gtk.Orientation.HORIZONTAL ?
            n_cells * view.cell_size * GRID_LABELBOX_RATIO :
            n_labels * view.cell_size
        );

        set_size_request (width, height);
    }
}
