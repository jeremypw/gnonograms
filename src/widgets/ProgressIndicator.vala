/* Holds all row or column clues for gnonograms
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
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */

namespace Gnonograms {
/** Widget to show working when generating or solving and allow cancel **/
public class ProgressIndicator : Gtk.Grid {
    private Gtk.Spinner spinner;
    private Gtk.Button cancel_button;
    private Gtk.Label label;

    public string text {
        set {
            label.label = value;
        }
    }

    public Cancellable? cancellable { get; set; }

    public ProgressIndicator () {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            column_homogeneous: false,
            column_spacing: 6,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        spinner = new Gtk.Spinner ();
        // spinner.get_style_context ().add_class ("progress");
        label = new Gtk.Label (null);
        // label.get_style_context ().add_class ("progress");
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        add (label);
        add (spinner);

        cancel_button = new Gtk.Button ();
        var img = new Gtk.Image.from_icon_name ("process-stop-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        img.set_tooltip_text (_("Cancel solving"));
        cancel_button.image = img;
        cancel_button.no_show_all = true;
        cancel_button.get_style_context ().add_class ("warn");
        img.get_style_context ().add_class ("warn");

        add (cancel_button);

        show_all ();

        cancel_button.clicked.connect (() => {
            if (cancellable != null) {
                cancellable.cancel ();
            }
        });

        realize.connect (() => {
            if (cancellable != null) {
                cancel_button.show ();
            }

            spinner.start ();
        });

        unrealize.connect (() => {
            if (cancellable != null) {
                cancellable = null;
                cancel_button.hide ();
            }

            spinner.stop ();
        });
    }
}
}
