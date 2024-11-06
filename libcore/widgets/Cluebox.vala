/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.ClueBox : Gtk.Widget {
    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    public const double WINDOW_CLUEBOX_RATIO = 0.3; // For simplicity give labelboxes fixed ratio of window dimensions
    public unowned View view { get; construct; }
    public bool holds_column_clues { get; construct; }
    // The number of cells each clue addresses, monitored by clues
    public uint n_cells { get; set; default = 0; }

    private Gee.ArrayList<Clue> clues;
    public ClueBox (View _view, bool _holds_column_clues) {
        Object (
            view: _view,
            holds_column_clues: _holds_column_clues
        );
    }

    construct {
        var orientation = holds_column_clues ? Gtk.Orientation.HORIZONTAL : Gtk.Orientation.VERTICAL;
        var layout = new Gtk.BoxLayout (orientation) {
            homogeneous = true,
            spacing = 0
        };
        set_layout_manager (layout);

        clues = new Gee.ArrayList<Clue> ();

        if (holds_column_clues) {
            set_minimum_height ();
            view.notify["default-height"].connect (set_minimum_height);
            view.controller.notify ["columns"].connect (add_remove_clues);
        } else {
            set_minimum_width ();
            view.notify["default-width"].connect (set_minimum_width);
            view.controller.notify ["rows"].connect (add_remove_clues);
        }
    }


    private void add_remove_clues () {
        var new_n_clues = holds_column_clues ? view.controller.columns : view.controller.rows;
        var new_n_cells = holds_column_clues ? view.controller.rows : view.controller.columns;

        if (n_cells != new_n_cells) {
            n_cells = new_n_cells;
        }

        if (clues.size != new_n_clues) {
            foreach (var clue in clues) {
                clue.label.unparent ();
                clue.label.destroy ();
            }

            clues.clear ();

            for (int index = 0; index < new_n_clues; index++) {
                var clue = new Clue (holds_column_clues, this);
                clues.add (clue);
                clue.label.set_parent (this);
            }
        }
    }

    private void set_minimum_width () {
        var width = (double) view.default_width * WINDOW_CLUEBOX_RATIO;
        set_size_request ((int) width, -1);
    }

    private void set_minimum_height () {
        var height = (double) view.default_height * WINDOW_CLUEBOX_RATIO;
        set_size_request (-1, (int) height);
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
