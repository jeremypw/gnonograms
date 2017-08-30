/* Holds all row or column clues for gnonograms-elementary
 * Copyright (C) 2010 - 2017  Jeremy Wootten
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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {
/** Widget to show working when generating or solving and allow cancel **/
public class Progress_indicator : Gtk.Grid {
    public signal void cancel ();

    private Gtk.Spinner spinner;
    private Gtk.Button cancel_button;
    private Gtk.Label label;

    public string text {
        set {
            label.label = value;
        }
    }

    public Cancellable? cancellable { get; set; }

    public Progress_indicator () {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            column_homogeneous: false,
            column_spacing: 6
        );
    }

    construct {
        spinner = new Gtk.Spinner ();
        label = new Gtk.Label (null);

        add (label);
        add (spinner);

        cancel_button = new Gtk.Button ();
        var img = new Gtk.Image.from_icon_name ("process-stop-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        img.set_tooltip_text (_("Cancel solving"));
        cancel_button.image = img;
        cancel_button.no_show_all = true;
        add (cancel_button);

        show_all ();

        if (cancellable != null) {
            cancellable.connect (() => {
                cancel ();
            });
        }

        cancel_button.clicked.connect (() => {
            if (cancellable != null) {
                cancellable.cancel ();
            }

            cancel ();
        });

        realize.connect (() => {
            if (cancellable != null) {
                cancel_button.show ();
            }

            spinner.start ();
        });

        unrealize.connect (() => {
            if (cancellable != null) {
                cancel_button.hide ();
            }

            spinner.stop ();
        });
    }
}
}
