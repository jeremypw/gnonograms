/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.AppPopover : Gtk.Popover {
    public Controller controller { get; construct; }
    public AppPopover (Controller controller) {
        Object (
            controller: controller
        );
    }
    construct {
        var app = (Gtk.Application)(GLib.Application.get_default ());

        var title_entry = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here"),
            margin_top = 12,
        };
        controller.bind_property ("game-name", title_entry, "text", BIDIRECTIONAL | SYNC_CREATE);

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
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (load_game_button);
        settings_box.append (save_game_button);
        settings_box.append (save_as_game_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (preferences_button);
        settings_box.append (shortcut_button);
        settings_box.append (about_button);

        child = settings_box;
    }
}
