 /*
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

public class Gnonograms.ClueBox : Gtk.Box {
    public View view { get; construct; }

    private uint n_clues = 0;
    private uint n_cells = 0;
    private List<unowned Clue> clues = null;

    public ClueBox (Gtk.Orientation _orientation, View view) {
        Object (
            view: view,
            homogeneous: true,
            spacing: 0,
            orientation: _orientation
        );
    }

    construct {
        view.notify["cell-size"].connect (() => {
            clues.foreach ((clue) => {
                clue.cell_size = view.cell_size;
            });

            set_size ();
        });

        view.controller.notify ["dimensions"].connect (() => {
            var new_n_clues = orientation == Gtk.Orientation.HORIZONTAL ?
                                              view.controller.dimensions.width :
                                              view.controller.dimensions.height;

            var new_n_cells = orientation == Gtk.Orientation.HORIZONTAL ?
                                             view.controller.dimensions.height :
                                             view.controller.dimensions.width;

            if (new_n_clues != n_clues || new_n_cells != n_cells) {
                n_clues = new_n_clues;
                n_cells = new_n_cells;
                change_n_clues ();
            }
        });
    }

    private Gnonograms.Clue? get_clue (uint index) {
        // var n_children = get_children ().length ();
        if (index >= n_clues) {
            return null;
        } else {
            return clues.nth_data (n_clues - index - 1);
        }
    }

    public string[] get_clues () {
        string[] clue_text = new string [n_clues];
        var index = n_clues;
        clues.@foreach ((clue) => { // Delivers widgets in reverse order they were added
            index--;
            clue_text[index] = clue.text;
        });

        return clue_text;
    }

    public void highlight (uint index, bool is_highlight) {
        var clue = get_clue (index);
        if (clue != null) {
            clue.highlight (is_highlight);
        }
    }

    public void unhighlight_all () {
        clues.foreach ((clue) => {
            clue.highlight (false);
        });
    }

    public void update_clue_text (uint index, string? txt) {
        var clue = get_clue (index);
        if (clue != null) {
            clue.text = txt ?? _(BLANKLABELTEXT);
        }
    }

    public void clear_formatting (uint index) {
        var clue = get_clue (index);
        if (clue != null) {
            clue.clear_formatting ();
        }
    }

    public void update_clue_complete (uint index, Gee.List<Block> grid_blocks) {
        var clue = get_clue (index);
        if (clue != null) {
            clue.update_complete (grid_blocks);
        }
    }

    private void change_n_clues () {
        clues.@foreach ((clue) => {
            clue.destroy ();
        });

        clues = null;

        for (var i = 0; i < n_clues; i++) {
            var clue = new Clue (orientation == Gtk.Orientation.HORIZONTAL) {
                n_cells = this.n_cells,
                cell_size = view.cell_size
            };

            append (clue);
            clues.append (clue);
        }

        set_size ();
    }

    private void set_size () {
        int width = (int)(orientation == Gtk.Orientation.HORIZONTAL ?
            n_clues * view.cell_size :
            n_cells * view.cell_size * GRID_LABELBOX_RATIO
        );

        int height = (int)(orientation == Gtk.Orientation.HORIZONTAL ?
            n_cells * view.cell_size * GRID_LABELBOX_RATIO :
            n_clues * view.cell_size
        );

        set_size_request (width, height);
    }
}
