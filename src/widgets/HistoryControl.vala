/* UI for move history for gnonograms-elementary
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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {

class HistoryControl : Gtk.Box {
    Gtk.Button button_back;
    Gtk.Button button_forward;

    public bool can_go_forward {
        set {
            button_forward.sensitive = value;
        }
    }

    public bool can_go_back {
        set {
            button_back.sensitive = value;
        }
    }

    public signal void go_forward ();
    public signal void go_back ();

    construct {
        button_back = new HistoryButton ("go-previous-symbolic", Gtk.IconSize.LARGE_TOOLBAR, _("Previous"));
        button_forward = new HistoryButton ("go-next-symbolic", Gtk.IconSize.LARGE_TOOLBAR, _("Next"));

        pack_start (button_back);
        pack_start (button_forward);

        button_forward.clicked.connect (on_button_forward_clicked);
        button_back.clicked.connect (on_button_back_clicked);
    }

    private void on_button_back_clicked () {
        go_back ();
    }

    private void on_button_forward_clicked () {
        go_forward ();
    }

    private class HistoryButton : Gtk.Button {
        public HistoryButton (string icon_name,  Gtk.IconSize icon_size, string tip) {
            Object (image: new Gtk.Image.from_icon_name (icon_name, icon_size));

            tooltip_text = tip;
            show_all ();
            sensitive = false;
        }

    }
}
}


