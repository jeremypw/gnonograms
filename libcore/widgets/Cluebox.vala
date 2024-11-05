/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.ClueBox : Gtk.Box {
    public unowned View view { get; construct; }
    // public double font_size { get; set; }
    // The number of cells each clue addresses, monitored by clues
    public uint n_cells { get; set; default = 0; }
    private Gee.ArrayList<Clue> clues;
    private uint width {
        get {
            return view.controller.columns;
        }
    }
    private uint height {
        get {
            return view.controller.rows;
        }
    }

    public ClueBox (Gtk.Orientation _orientation, View view) {
        Object (
            view: view,
            orientation: _orientation
        );
    }

    construct {
        homogeneous = true;
        spacing = 0;

        clues = new Gee.ArrayList<Clue> ();
        view.controller.notify ["rows"].connect (on_dimensions_changed);
        view.controller.notify ["columns"].connect (on_dimensions_changed);

        on_dimensions_changed ();
    }


    private void on_dimensions_changed () {
        if (width == 0 || height == 0) {
            return;
        }

        var new_n_clues = orientation == Gtk.Orientation.HORIZONTAL ?
                                          width :
                                          height;

        var new_n_cells = orientation == Gtk.Orientation.HORIZONTAL ?
                                         height :
                                         width;
        foreach (var clue in clues) {
            remove (clue.label);
        }

        clues.clear ();
        n_cells = new_n_cells;
        for (int index = 0; index < new_n_clues; index++) {
            var clue = new Clue (orientation, this);
            clues.add (clue);
            append (clue.label);
        }
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
