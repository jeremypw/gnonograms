/*
 * Copyright (C) 2010-2022  Jeremy Wootten
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

    private class Gnonograms.RestartButton : Gnonograms.HeaderButton {
        public bool restart_destructive { get; set; }

        construct {
            restart_destructive = false;

            notify["restart-destructive"].connect (() => {
                if (restart_destructive) {
                    add_css_class ("warn");
                    remove_css_class ("dim");
                } else {
                    remove_css_class ("warn");
                    add_css_class ("dim");
                }
            });

            bind_property ("sensitive", this, "restart-destructive");
        }

        public RestartButton (string icon_name, string action_name, string text) {
            base (icon_name, action_name, text);
        }
    }
