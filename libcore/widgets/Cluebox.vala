/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.ClueBox : Gtk.Box {
    public unowned View view { get; construct; }
    public int font_size { get; private set; }
    // The number of cells each clue addresses, monitored by clues
    public uint n_cells { get; set; default = 0; }
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

        view.notify["cell-size"].connect (set_size);
    }

    private void set_size () {
        font_size = (int) ((double) view.cell_size * 0.525);
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
