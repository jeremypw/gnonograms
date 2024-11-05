/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.Dialogs.Preferences : Granite.Dialog {

    public Preferences (Gtk.Window? parent) {
        Object (
            title: _("Preferences"),
            transient_for: parent
        );
    }

    construct {
        var grade_setting = new Gtk.DropDown.from_strings ( Difficulty.all_human ());
        var row_setting = new Gtk.SpinButton (
            new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            5.0,
            0
        ) {
            snap_to_ticks = true,
            orientation = Gtk.Orientation.HORIZONTAL,
            width_chars = 3,
        };

        var column_setting = new Gtk.SpinButton (
            new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            5.0,
            0
        ) {
            snap_to_ticks = true,
            orientation = Gtk.Orientation.HORIZONTAL,
            width_chars = 3,
        };

        //TODO Add Clue help switch

        var main_box = new Gtk.Box (VERTICAL, 12);
        main_box.append (grade_setting);
        main_box.append (row_setting);
        main_box.append (column_setting);

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
