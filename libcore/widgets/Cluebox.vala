/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.ClueBox : Gtk.Widget {
    static construct {
        set_layout_manager_type (typeof (Gtk.BoxLayout));
    }

    const int PIX_TO_PANGO_FONT = 1024 / 2;

    public unowned View view { get; construct; }
    public bool holds_column_clues { get; construct; }
    public uint n_cells { get; set; default = 0; }// The number of cells each clue addresses, monitored by clues
    public double cell_size { get; set; }
    public Pango.FontDescription font_desc { get; set; }

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
            homogeneous = false,
            spacing = 0
        };
        set_layout_manager (layout);

        margin_bottom = holds_column_clues ? 0 : 6;
        margin_end = holds_column_clues ? 6 : 0;
        clues = new Gee.ArrayList<Clue> ();
        font_desc = Pango.FontDescription.from_string ("Arial 10");
        var mode = holds_column_clues ? Gtk.SizeGroupMode.HORIZONTAL : Gtk.SizeGroupMode.VERTICAL;

        if (holds_column_clues) {
            hexpand = false;
            view.controller.notify ["columns"].connect (add_remove_clues);
        } else {
            vexpand = false;
            view.controller.notify ["rows"].connect (add_remove_clues);
        }

        notify["cell-size"].connect (update_size_request);
    }

    private void update_size_request () {
            font_desc.set_absolute_size (cell_size * PIX_TO_PANGO_FONT);
            var index = 0.0;
            var size = (int) cell_size;
            var diff = cell_size - (double) size;
            var shortfall = 0.0;
            // Assign label widths to match grid lines as closely as possible.
            // As the cell dimensions are non-integral we have to vary the (integral) label widths
            var box_size = 0;
            foreach (Clue clue in clues) {
                var makeup = 0;
                if (shortfall >= 1.0) {
                    makeup = 1;
                    shortfall-= 1.0;
                }

                var label = clue.label;
                if (holds_column_clues) {
                    label.width_request =  size + makeup;
                    box_size += label.width_request;
                } else {
                    label.height_request = size + makeup;
                    box_size += label.height_request;
                }

                index++;
                shortfall += diff;
            }

            if (holds_column_clues) {
                set_size_request (box_size, (int) (cell_size / 2.0 * (n_cells / 3 + 2)));
            } else {
                set_size_request ((int) (cell_size / 2.0 * (n_cells / 3 + 2)), box_size);
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

        update_size_request ();
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
