/* Viewer class for Gnonograms3
 * Handles user interface
 * Copyright (C) 2010-2011  Jeremy Wootten
 *
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */

namespace Gnonograms {
public class View : Gtk.Window {
    public Gnonograms.LabelBox row_box {get; construct;}
    public Gnonograms.LabelBox column_box {get; construct;}
    public Gnonograms.CellGrid cells {get; construct;}

    construct {
        title = _("Gnonograms3");
        set_position (Gtk.WindowPosition.CENTER);
        resizable = false;
    }

    public View (Gnonograms.LabelBox rb, Gnonograms.LabelBox cb, Gnonograms.CellGrid cg) {
        Object (row_box: rb,
                column_box: cb,
                cells: cg);

        var grid = new Gtk.Grid ();
        grid.attach (row_box, 0, 1, 1, 2); /* Clues for rows */
        grid.attach (column_box, 1, 0, 2, 1); /* Clues for columns */
        grid.attach (cells, 1, 1, 2, 2);

        add (grid);
        show_all ();
    }
}
}
