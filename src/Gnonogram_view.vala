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
    Gtk.Box info_box;
    Gtk.Label name_label;
    
    public View () {
        name_label =  new Gtk.Label ("Test Gtk.Label");
        name_label.set_alignment ((float)0.0, (float)0.5);

        var name_fr = new Gtk.Frame (null);
        name_fr.add (name_label);

        info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        info_box.set_homogeneous (false);
        info_box.add (name_fr);

        var info_frame = new Gtk.Frame (null);
        info_frame.add (info_box);

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        vbox.set_homogeneous (false);
        vbox.pack_start (info_frame, true, true, 0);
        add (vbox);

        this.title = _("Gnonograms3");
        this.set_position (Gtk.WindowPosition.CENTER);
        this.resizable = false;
    }
}
}
