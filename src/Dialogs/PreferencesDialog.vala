/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.Dialogs.Preferences : Granite.Dialog {
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

        var main_box = new Gtk.Box (VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12
        };
        main_box.append (grade_preference);
        main_box.append (row_preference);
        main_box.append (column_preference);

        get_content_area ().append (main_box);
        add_button (_("Close"), Gtk.ResponseType.APPLY);

        settings.bind ("columns", column_setting, "value", DEFAULT);
        settings.bind ("rows", row_setting, "value", DEFAULT);

        grade_setting.selected = settings.get_enum ("grade");
        grade_setting.notify["selected"].connect (() => {
            settings.set_enum ("grade", (Difficulty)(grade_setting.selected));
        });
    }

    private class PreferenceRow : Gtk.Box {
        public string text { get; construct; }
        public Gtk.Widget widget { get; construct; }
        public PreferenceRow (string text, Gtk.Widget setting_widget) {
            Object (
                text: text,
                widget: setting_widget
            );
        }

        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            margin_top = 3;
            margin_bottom = 6;
            spacing = 12;
            hexpand = true;

            var label = new Gtk.Label (text) {
                halign = Gtk.Align.START
            };

            widget.halign = Gtk.Align.END;
            widget.hexpand = true;

            append (label);
            append (widget);
        }
    }
}
