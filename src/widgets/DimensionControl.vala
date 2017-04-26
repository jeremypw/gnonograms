/* Displays clues for gnonograms-elementary
 * Copyright (C) 2010-2017  Jeremy Wootten
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

namespace Gnonograms {

class DimensionControl : Gtk.Button {
    private Gtk.Popover popover;
    private Gtk.Scale rows;
    private Gtk.Scale cols;

    public signal void changed (uint rows, uint cols);

    construct {
        popover = new Gtk.Popover (this);
        var grid = new Gtk.Grid ();
        popover.add (grid);
        popover.set_size_request (200, -1);

        rows = new Gtk.HScale.with_range (5.0, MAXSIZE, 5.0);
        cols = new Gtk.HScale.with_range (5.0, MAXSIZE, 5.0);

        configure_scale (rows);
        configure_scale (cols);

        var row_label = new Gtk.Label (_("Rows"));
        var col_label = new Gtk.Label (_("Columns"));

        row_label.xalign = 1;
        col_label.xalign = 1;

        grid.attach (row_label, 0, 0, 1, 1);
        grid.attach (col_label, 0, 1, 1, 1);
        grid.attach (rows, 1, 0, 1, 1);
        grid.attach (cols, 1, 1, 1, 1);

        grid.row_spacing = 12;
        grid.column_spacing = 6;
        grid.border_width = 12;

        clicked.connect (() => {
            popover.show_all ();
        });

        popover.closed.connect (on_popover_closed);
    }

    public DimensionControl (Dimensions dimensions) {
        set_label (_("Size of grid"));
        rows.set_value ((double)(dimensions.height));
        cols.set_value ((double)(dimensions.width));
    }

    private void on_popover_closed () {
        /* Constrain size changes to multiples of 5 */
        var row_val = rows.get_value () / 5.0;
        var col_val = cols.get_value () / 5.0;

        if ((uint)row_val != row_val || (uint)col_val != col_val) {
            return;
        }

        changed ((uint)row_val * 5, (uint)col_val * 5);
    }

    private void configure_scale (Gtk.Scale scale) {
        for (double val = scale.adjustment.lower;
             val <= scale.adjustment.upper;
             val += scale.adjustment.step_increment) {

            scale.add_mark (val, Gtk.PositionType.BOTTOM, null);
        }

        scale.hexpand = true;
        scale.draw_value = true;
        scale.value_pos = Gtk.PositionType.LEFT;
    }
}
}
