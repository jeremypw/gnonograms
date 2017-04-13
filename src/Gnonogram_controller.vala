/* Controller class for Gnonograms3
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
public class Controller : GLib.Object {
    private View gnonogram_view;
    public string game_path {get; set;}

    public Gtk.Window window {
        get {
            return (Gtk.Window)gnonogram_view;
        }
    }

    public Controller(string game_path) {
        Object (game_path: game_path);
        create_view();
    }

    private void create_view() {
        gnonogram_view = new Gnonograms.View ();
        gnonogram_view.show_all();
    }

    private void save_state () {

    }

    public void quit () {
        save_state ();
    }
}
}
