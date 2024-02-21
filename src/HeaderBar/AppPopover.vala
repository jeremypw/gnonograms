/* AppPopover.vala
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
public class Gnonograms.AppPopover : Gtk.Popover {
    public signal void apply_settings ();

    private Gtk.DropDown grade_setting;
    private Gtk.SpinButton row_setting;
    private Gtk.SpinButton column_setting;
    private Gtk.Entry title_setting;
    private Gtk.ColorDialogButton filled_color_setting;
    private Gtk.ColorDialogButton empty_color_setting;

    public Difficulty grade {
        get {
            return (Difficulty) (grade_setting.get_selected ());
        }

        set {
            grade_setting.set_selected (
                ((uint) value).clamp (
                    MIN_GRADE,
                    Difficulty.MAXIMUM
                )
            );
        }
    }

    public uint rows {
        get {
            return (uint)(row_setting.@value);
        }

        set {
            row_setting.@value = value;
        }
    }

    public uint columns {
        get {
            return (uint)(column_setting.@value);
        }

        set {
            column_setting.@value = value;
        }
    }

    public string title {
        get {
            return title_setting.text;
        }

        set {
            title_setting.text = value;
        }
    }

    public string filled_color {
        owned get {
            return filled_color_setting.get_rgba ().to_string ();
        }

        set {
            Gdk.RGBA color = {};
            if (color.parse (value)) {
                filled_color_setting.set_rgba (color);
            }
        }
    }

    public string empty_color {
        owned get {
            return empty_color_setting.get_rgba ().to_string ();
        }

        set {
            Gdk.RGBA color = {};
            if (color.parse (value)) {
                empty_color_setting.set_rgba (color);
            }
        }
    }

    construct {
        autohide = false;
        grade_setting = new Gtk.DropDown.from_strings (Difficulty.all_human ());

        row_setting = new Gtk.SpinButton (
            new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            5.0,
            0
        ) {
            snap_to_ticks = true,
            orientation = Gtk.Orientation.HORIZONTAL,
            width_chars = 3,
        };

        column_setting = new Gtk.SpinButton (
            new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            5.0,
            0
        ) {
            snap_to_ticks = true,
            orientation = Gtk.Orientation.HORIZONTAL,
            width_chars = 3,
        };

        title_setting = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here")
        };

        filled_color_setting = new Gtk.ColorDialogButton (new Gtk.ColorDialog ());
        empty_color_setting = new Gtk.ColorDialogButton (new Gtk.ColorDialog ());

        var settings_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 12,
            column_spacing = 12,
            margin_start = margin_end = margin_top = 12,
            margin_bottom = 24
        };
        settings_grid.attach (new Gtk.Label (_("Name:")), 0, 0, 1);
        settings_grid.attach (title_setting, 1, 0, 3);
        settings_grid.attach (new Gtk.Label (_("Difficulty:")), 0, 1, 1);
        settings_grid.attach (grade_setting, 1, 1, 3);
        settings_grid.attach (new Gtk.Label (_("Rows:")), 0, 2, 1);
        settings_grid.attach (row_setting, 1, 2, 1);
        settings_grid.attach (new Gtk.Label (_("Columns:")), 0, 3, 1);
        settings_grid.attach (column_setting, 1, 3, 1);
        settings_grid.attach (new Gtk.Label (_("Filled Color:")), 0, 4, 1);
        settings_grid.attach (filled_color_setting, 1, 4, 1);
        settings_grid.attach (new Gtk.Label (_("Empty Color:")), 0, 5, 1);
        settings_grid.attach (empty_color_setting, 1, 5, 1);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        var apply_button = new Gtk.Button.with_label (_("Apply"));
        default_widget = apply_button;
        cancel_button.clicked.connect (() => {
            hide ();
        });
        apply_button.clicked.connect (() => {
            apply_settings ();
            hide ();
        });
        var popover_actions = new Gtk.ActionBar ();
        popover_actions.pack_start (cancel_button);
        popover_actions.pack_end (apply_button);

        var main_widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        // main_grid.append (size_grid);
        main_widget.append (settings_grid);
        main_widget.append (popover_actions);

        child = main_widget;
    }
}
