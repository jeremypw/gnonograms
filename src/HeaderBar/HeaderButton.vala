/* View.vala
 * Copyright (C) 2010-2021  Jeremy Wootten
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
 *  Author: Jeremy Wootten <jeremywootten@gmail.com>
 */

    public class Gnonograms.HeaderButton : Gtk.Button {
        public HeaderButton (string icon_name, string action_name, string text) {
            Object (
                icon_name: icon_name,
                action_name: action_name,
                tooltip_markup: Granite.markup_accel_tooltip (
                    View.app.get_accels_for_action (action_name), text
                )
            );
        }

        construct {
            valign = Gtk.Align.CENTER;
        }

    }
