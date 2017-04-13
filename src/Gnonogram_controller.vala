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

public class Gnonogram_controller : GLib.Object {
    public Gnonogram_view gnonogram_view { get; private set; }


    public Gnonogram_controller(string game_path) {
        Object (game_path: game_path);
        create_view();
    }

    private void create_view() {
        gnonogram_view = new Gnonogram_view (null, null, null);
        gnonogram_view.show_all();
    }
}
