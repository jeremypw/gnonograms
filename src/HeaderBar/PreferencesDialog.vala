/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.PreferencesDialog : Granite.Dialog {
    construct {
        set_default_size (400, 100);
        resizable = false;
        var grade_setting = new Gtk.DropDown.from_strings ( Difficulty.all_human ());
        var grade_preference = new PreferenceRow (_("Degree of difficulty"), grade_setting);

        var row_setting = new Gtk.SpinButton (
            new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            5.0,
            0
        ) {
            snap_to_ticks = true,
            orientation = Gtk.Orientation.HORIZONTAL,
            width_chars = 3,
        };

        var row_preference = new PreferenceRow (_("Rows"), row_setting);

        var column_setting = new Gtk.SpinButton (
            new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            5.0,
            0
        ) {
            snap_to_ticks = true,
            orientation = Gtk.Orientation.HORIZONTAL,
            width_chars = 3
        };

        var column_preference = new PreferenceRow (_("Columns"), column_setting);
        //TODO Add Clue help switch

        var empty_color_dialog = new Gtk.ColorDialog () {
            title = _("Filled Color"),
            with_alpha = true
        };
        var empty_color_button = new Gtk.ColorDialogButton (empty_color_dialog);
        var empty_color = settings.get_string ("empty-color");
        var rgba = Gdk.RGBA ();
        if (rgba.parse (empty_color)) {
            empty_color_button.set_rgba (rgba);
        }

        empty_color_button.notify["rgba"].connect (() => {
            settings.set_string ("empty-color", empty_color_button.get_rgba ().to_string ());
        });
        var empty_color_preference = new PreferenceRow (_("Color of empty cells"), empty_color_button);

        var filled_color_dialog = new Gtk.ColorDialog () {
            title = _("Filled Color"),
            with_alpha = true
        };
        var filled_color_button = new Gtk.ColorDialogButton (filled_color_dialog);
        var filled_color = settings.get_string ("filled-color");
        if (rgba.parse (filled_color)) {
            filled_color_button.set_rgba (rgba);
        }

        filled_color_button.notify["rgba"].connect (() => {
            warning ("filled color now %s", filled_color_button.get_rgba ().to_string ());
            settings.set_string ("filled-color", filled_color_button.get_rgba ().to_string ());
        });

        var filled_color_preference = new PreferenceRow (_("Color of filled cells"), filled_color_button);

        var follow_system_switchmodelbutton = new Granite.SwitchModelButton (_("Follow System Style")) {
            margin_top = 3
        };

        var color_mode_switch = new Granite.ModeSwitch.from_icon_name (
            "weather-clear-symbolic", 
            "weather-clear-night-symbolic"
        ) {
            primary_icon_tooltip_text = _("Light"),
            secondary_icon_tooltip_text = _("Dark")
        };
        var color_mode_preference = new PreferenceRow (_("Color Style"), color_mode_switch) {
            margin_start = margin_start + 12
        };
        var color_revealer = new Gtk.Revealer ();
        color_revealer.set_child (color_mode_preference);
        follow_system_switchmodelbutton.bind_property (
            "active", 
            color_revealer, "reveal-child", 
            INVERT_BOOLEAN | SYNC_CREATE
        );

        var main_box = new Gtk.Box (VERTICAL, 12) {
            margin_start = 12
        };

        main_box.append (grade_preference);
        main_box.append (row_preference);
        main_box.append (column_preference);
        main_box.append (filled_color_preference);
        main_box.append (empty_color_preference);
        main_box.append (follow_system_switchmodelbutton);
        main_box.append (color_revealer);

        get_content_area ().append (main_box);
        add_button (_("Close"), Gtk.ResponseType.APPLY);

        settings.bind ("columns", column_setting, "value", DEFAULT);
        settings.bind ("rows", row_setting, "value", DEFAULT);

        grade_setting.selected = settings.get_enum ("grade");
        grade_setting.notify["selected"].connect (() => {
            settings.set_enum ("grade", (Difficulty)(grade_setting.selected));
        });
    }
}
