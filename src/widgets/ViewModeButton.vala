/* View class for gnonograms-elementary - displays user interface
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
/** ModeButton used by View in headbar to switch between SETTING and SOLVING modes **/
public class ViewModeButton : Granite.Widgets.ModeButton {
    /** PUBLIC **/
    public GameState mode {
        set {
            if (value == GameState.SETTING) {
                set_active (setting_index);
            } else {
                set_active (solving_index);
            }
        }
    }

    public ViewModeButton () {
        /* Cannot do this in construct */
        setting_index = append (setting_icon);
        solving_index = append (solving_icon);
    }

    construct {
        /* Icons used are provisional */
        setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        solving_icon = new Gtk.Image.from_icon_name ("process-working-symbolic", Gtk.IconSize.MENU);

        setting_icon.set_data ("mode", GameState.SETTING);
        solving_icon.set_data ("mode", GameState.SOLVING);

        setting_icon.tooltip_text = _("Draw a pattern");
        solving_icon.tooltip_text = _("Solve a puzzle");
    }

    /** PRIVATE **/
    private int setting_index;
    private int solving_index;
    private Gtk.Image setting_icon;
    private Gtk.Image solving_icon;


}
}
