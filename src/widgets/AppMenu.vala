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
    private AppPopover app_popover;
    private AppSetting grade_setting;
    private AppSetting row_setting;
    private AppSetting column_setting;
    private AppSetting title_setting;
    private AppSetting strikeout_setting;
    private Gtk.Grid grid;

    public Dimensions dimensions { get; set; }
    public Difficulty grade { get; set; }
    public string title { get; set; }
    public bool strikeout_complete { get; set; }

    construct {
        grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.row_spacing = 6;
        grid.column_spacing = 6;
        grid.column_homogeneous = false;

        grade_setting = new GradeChooser ();
        row_setting = new ScaleGrid (_("Rows"));
        column_setting = new ScaleGrid (_("Columns"));
        title_setting = new TitleEntry ();
        strikeout_setting = new SettingSwitch (_("Strike out complete blocks"));

        int pos = 0;
        add_setting (ref pos, grade_setting);
        add_setting (ref pos, row_setting);
        add_setting (ref pos, column_setting);
        add_setting (ref pos, title_setting);
        add_setting (ref pos, strikeout_setting);

        app_popover = new AppPopover ();
        app_popover.add (grid);
        set_popover (app_popover);
        app_popover.apply_settings.connect (() => {
            update_properties ();
        });

        notify["dimensions"].connect (() => {
            update_dimension_settings ();
        });

        notify["grade"].connect (() => {
            update_grade_setting ();
        });

        notify["title"].connect (() => {
            update_title_setting ();
        });

        notify["strikeout-complete"].connect (() => {
            update_strikeout_setting ();
        });

        toggled.connect (() => { /* Allow parent to set values first */
            if (active) {
                update_dimension_settings ();
                update_grade_setting ();
                update_title_setting ();
                update_strikeout_setting ();
                popover.show_all ();
            }
        });
    }

    public AppMenu () {
        Object (
            image: new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR),
            tooltip_text: _("Options")
        );
    }

    private void update_dimension_settings () {
        row_setting.set_value (dimensions.rows ());
        column_setting.set_value (dimensions.cols ());
    }

    private void update_grade_setting () {
        grade_setting.set_value ((uint)grade);
    }

    private void update_title_setting () {
        title_setting.set_text (title);
    }

    private void update_strikeout_setting () {
        strikeout_setting.set_state (strikeout_complete);
    }

    private void update_properties () {
        var rows = (uint)(row_setting.get_value ());
        var cols = (uint)(column_setting.get_value ());
        dimensions = {cols, rows};
        grade = (Difficulty)(grade_setting.get_value ());
        title = title_setting.get_text ();
        strikeout_complete = strikeout_setting.get_state ();
    }

    private void add_setting (ref int pos, AppSetting setting) {
        var label = setting.get_heading ();
        label.xalign = 1;
        grid.attach (label, 0, pos, 1, 1);
        grid.attach (setting.get_chooser (), 1, pos, 1, 1);
        pos++;
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
}
}
