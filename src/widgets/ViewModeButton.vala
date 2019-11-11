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

    public Difficulty grade {
        set {
            ///TRANSLATORS: '%s' is a placeholder for an adjective describing the difficulty of the puzze. It can be moved but not translated.
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
        setting_icon = new ModeImage ("edit-symbolic", _("Draw pattern"));
        solving_icon = new ModeImage ("head-thinking", _("Solve puzzle"));
        generating_icon = new ModeImage ("list-add-symbolic", _("Generate new random puzzle"));

        setting_icon.set_data ("mode", GameState.SETTING);
        solving_icon.set_data ("mode", GameState.SOLVING);
        generating_icon.set_data ("mode", GameState.GENERATING);

        mode_changed.connect (() => {
            if (selected == setting_index) {
                mode = GameState.SETTING;
            } else if (selected == solving_index) {
                mode = GameState.SOLVING;
            } else if (selected == generating_index) {
                mode = GameState.GENERATING;
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
                case GameState.GENERATING:
                    set_active (generating_index);
                    break;
                default:
                    break;
            }
        });
    }

    private class ModeImage : Gtk.Image {
        construct {
            valign = Gtk.Align.CENTER;
        }

        public ModeImage (string icon_name, string tooltip) {
            Object (
                icon_name: icon_name,
                tooltip_text: tooltip,
                icon_size: Gtk.IconSize.LARGE_TOOLBAR
            );
        }
    }
}
}
