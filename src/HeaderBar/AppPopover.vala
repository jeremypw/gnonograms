/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.AppPopover : Gtk.Popover {
    private Controller controller = Controller.get_default ();

    construct {
        var app = (Gtk.Application)(GLib.Application.get_default ());

        var title_entry = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here"),
            margin_top = 12,
        };
        title_entry.bind_property ("text", controller, "game-name", BIDIRECTIONAL);


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

        var load_game_button = new PopoverButton (_("Load"), ACTION_PREFIX + ACTION_OPEN);
        var save_game_button = new PopoverButton (_("Save"), ACTION_PREFIX + ACTION_SAVE);
        var save_as_game_button = new PopoverButton (_("Save to Different File"), ACTION_PREFIX + ACTION_SAVE_AS);
        var preferences_button = new PopoverButton (_("Preferences"), ACTION_PREFIX + ACTION_PREFERENCES);
        var shortcut_button = new PopoverButton (_("Keyboard Shortcuts"), ACTION_PREFIX + ACTION_SHORTCUT_WINDOW);
        var about_button = new PopoverButton (_("About Gnonograms"), ACTION_PREFIX + ACTION_ABOUT_WINDOW);

        var settings_box = new Gtk.Box (VERTICAL, 3) {
            margin_start = 12,
            margin_end = 12,
        };
        settings_box.append (title_entry);
        settings_box.append (grade_preference);
        settings_box.append (row_preference);
        settings_box.append (column_preference);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (load_game_button);
        settings_box.append (save_game_button);
        settings_box.append (save_as_game_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (preferences_button);
        settings_box.append (shortcut_button);
        settings_box.append (about_button);

        child = settings_box;

        // controller.bind_property ("columns", column_setting, "value", BIDIRECTIONAL);
        // controller.bind_property ("rows", row_setting, "value", BIDIRECTIONAL);
        // TODO Apply dumension settings on popdown
        
        grade_setting.selected = controller.generator_grade;
        grade_setting.notify["selected"].connect (() => {
            controller.generator_grade = (Difficulty)(grade_setting.selected);
        });
    }
}
