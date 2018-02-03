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
    public GameState mode {
        get {
            if (selected == setting_index) {
                return GameState.SETTING;
            } else if (selected == solving_index) {
                return GameState.SOLVING;
            } else if (selected == generating_index) {
                    return GameState.GENERATING;
            } else {
                return GameState.UNDEFINED;
            }
        }

        set {
            switch (value) {
                case GameState.SETTING:
                    set_active (setting_index);
                    break;
                case GameState.SOLVING:
                    set_active (solving_index);
                    break;
                case GameState.GENERATING:
                    set_active (generating_index);
                    break;
                default:
                    assert_not_reached ();
            }
        }
    }

    public Difficulty grade {
        set {
            generating_icon.tooltip_text = _("Generate %s puzzle").printf (value.to_string ());
        }
    }

    private int setting_index;
    private int solving_index;
    private int generating_index;
    private Gtk.Image setting_icon;
    private Gtk.Image solving_icon;
    private Gtk.Image generating_icon;

    public ViewModeButton () {
        /* Cannot do this in construct */
        setting_index = append (setting_icon);
        solving_index = append (solving_icon);
        generating_index = append (generating_icon);
    }

    construct {
        /* Icons used are provisional */
        setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        solving_icon = new Gtk.Image.from_icon_name ("process-working-symbolic", Gtk.IconSize.MENU);
        generating_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);

        setting_icon.set_data ("mode", GameState.SETTING);
        solving_icon.set_data ("mode", GameState.SOLVING);
        generating_icon.set_data ("mode", GameState.GENERATING);

        setting_icon.tooltip_text = _("Draw pattern");
        solving_icon.tooltip_text = _("Solve puzzle");
        generating_icon.tooltip_text = _("Generate new random puzzle");
    }
}
}
