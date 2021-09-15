/* View class for gnonograms - displays user interface
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
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */

namespace Gnonograms {
/** ModeButton used by View in headbar to switch between SETTING and SOLVING modes **/
public class ViewModeButton : Granite.Widgets.ModeButton {
    /** PUBLIC **/
    public GameState mode {get; set;}

    private int setting_index;
    private int solving_index;
    private Gtk.Image setting_icon;
    private Gtk.Image solving_icon;

    public ViewModeButton () {
        /* Cannot do this in construct */
        setting_index = append (setting_icon);
        solving_index = append (solving_icon);
    }

    construct {
        Gtk.IconTheme.get_default ().add_resource_path ("/com/github/jeremypw/gnonograms");

        setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = _("Draw pattern")
        };

        solving_icon = new Gtk.Image.from_icon_name ("head-thinking", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = _("Solve puzzle")
        };

        setting_icon.set_data ("mode", GameState.SETTING);
        solving_icon.set_data ("mode", GameState.SOLVING);

        mode_changed.connect (() => {
            if (selected == setting_index) {
                mode = GameState.SETTING;
            } else if (selected == solving_index) {
                mode = GameState.SOLVING;
            } else {
                mode = GameState.UNDEFINED;
            }
        });

        notify["mode"].connect (() => {
            switch (mode) {
                case GameState.SETTING:
                    set_active (setting_index);
                    break;
                case GameState.SOLVING:
                    set_active (solving_index);
                    break;
                default:
                    break;
            }
        });
    }
}
}
