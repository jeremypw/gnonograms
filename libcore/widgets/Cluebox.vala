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
    public unowned View view { get; construct; }
    public uint n_cells { get; set; default = 0; } // The number of cells each clue addresses, monitored by clues
    private Gee.ArrayList<Clue> clues;

    public ClueBox (Gtk.Orientation _orientation, View view) {
        Object (
            view: view,
            homogeneous: true,
            spacing: 0,
            hexpand: _orientation == Gtk.Orientation.HORIZONTAL ? false : true,
            vexpand: _orientation == Gtk.Orientation.HORIZONTAL ? true : false,
            orientation: _orientation
        );
    }

    construct {
        clues = new Gee.ArrayList<Clue> ();
        view.controller.notify ["dimensions"].connect (() => {
            var new_n_clues = orientation == Gtk.Orientation.HORIZONTAL ?
                                              view.controller.dimensions.width :
                                              view.controller.dimensions.height;

            var new_n_cells = orientation == Gtk.Orientation.HORIZONTAL ?
                                             view.controller.dimensions.height :
                                             view.controller.dimensions.width;

            foreach (var clue in clues) {
                remove (clue.label);
            }
            clues.clear ();
            n_cells = new_n_cells;
            for (int index = 0; index < new_n_clues; index++) {
                var clue = new Clue (orientation == Gtk.Orientation.HORIZONTAL, this);
                clues.add (clue);
                append (clue.label);
            }
        });
    }

    public string[] get_clue_texts () {
        string[] clue_texts = {};
        foreach (var clue in clues) {
            clue_texts += clue.text;
        }

        return clue_texts;
    }

    public void highlight (uint index, bool is_highlight) {
        if (index < clues.size) {
            clues[(int)index].highlight (is_highlight);
        }
    }

    public void unhighlight_all () {
        foreach (var clue in clues) {
            clue.highlight (false);
        }
    }

    public void update_clue_text (uint index, string? text) {
        if (index < clues.size) {
            clues[(int)index].text = text ?? _(BLANKLABELTEXT);
        }
    }

    public void clear_formatting (uint index) {
        if (index < clues.size) {
            clues[(int)index].clear_formatting ();
        }
    }

    public void update_clue_complete (uint index, Gee.List<Block> grid_blocks) {
        if (index < clues.size) {
            clues[(int)index].update_complete (grid_blocks);
        }
    }
}
