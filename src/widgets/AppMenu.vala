/* Displays clues for gnonograms
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

namespace Gnonograms {

class AppMenu : Gtk.MenuButton {
    public unowned Controller controller { get; construct; }

    public AppMenu (Controller controller) {
        Object (
            image: new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR),
            tooltip_text: _("Options"),
            controller: controller
        );
    }

    construct {
        var grid = new Gtk.Grid () {
            margin = 6,
            margin_top = 12,
            row_spacing = 6,
            column_homogeneous = false
        };

        var grade_setting = new GradeChooser ();
        var row_setting = new DimensionSpinButton ();
        var column_setting = new DimensionSpinButton ();
        var title_setting = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here")
        };

        grid.attach (new SettingLabel (_("Name:")), 0, 0, 1);
        grid.attach (title_setting, 1, 0, 3);
        grid.attach (new SettingLabel (_("Difficulty:")), 0, 1, 1);
        grid.attach (grade_setting, 1, 1, 3);
        grid.attach (new SettingLabel (_("Rows:")), 0, 2, 1);
        grid.attach (row_setting, 1, 2, 1);
        grid.attach (new SettingLabel (_("Columns:")), 0, 3, 1);
        grid.attach (column_setting, 1, 3, 1);

        var app_popover = new AppPopover ();
        app_popover.add (grid);
        set_popover (app_popover);

        app_popover.apply_settings.connect (() => {
            controller.generator_grade = grade_setting.grade;
            controller.dimensions = {(uint)column_setting.@value, (uint)row_setting.@value};
            controller.game_name = title_setting.text;
        });

        toggled.connect (() => { /* Allow parent to set values first */
            if (active) {
                grade_setting.grade = controller.generator_grade;
                row_setting.value =  (double)(controller.dimensions.height);
                column_setting.value =  (double)(controller.dimensions.width);
                title_setting.text = controller.game_name;
                popover.show_all ();
            }
        });
    }

    /** Popover that can be cancelled with Escape and closed by Enter **/
    private class AppPopover : Gtk.Popover {
        private bool cancelled = false;
        public signal void apply_settings ();
        public signal void cancel ();

        construct {
            closed.connect (() => {
                if (!cancelled) {
                    apply_settings ();
                } else {
                    cancel ();
                }

                cancelled = false;
            });

            key_press_event.connect ((event) => {
                cancelled = (event.keyval == Gdk.Key.Escape);

                if (event.keyval == Gdk.Key.KP_Enter || event.keyval == Gdk.Key.Return) {
                    hide ();
                }
            });
        }
    }

    private class SettingLabel : Gtk.Label {
        public SettingLabel (string text) {
            Object (
                label: text,
                xalign: 1.0f
            );
        }
    }
}
}
