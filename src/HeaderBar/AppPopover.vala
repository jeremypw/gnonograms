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

        var zoom_smaller_button = new PopoverButton ("", ACTION_PREFIX + ACTION_ZOOM_SMALLER) {
            icon_name = "zoom-out-symbolic"
        };
        zoom_smaller_button.tooltip_markup = Granite.markup_accel_tooltip (
            app.get_accels_for_action (zoom_smaller_button.action_name),
            _("Shrink Window")
        );
        var zoom_default_button = new PopoverButton ("", ACTION_PREFIX + ACTION_ZOOM_DEFAULT) {
            icon_name = "zoom-original-symbolic"
        };
        zoom_default_button.tooltip_markup = Granite.markup_accel_tooltip (
            app.get_accels_for_action (zoom_default_button.action_name),
            _("Default Window Size")
        );
        var zoom_larger_button = new PopoverButton ("", ACTION_PREFIX + ACTION_ZOOM_LARGER) {
            icon_name = "zoom-in-symbolic"
        };
        zoom_larger_button.tooltip_markup = Granite.markup_accel_tooltip (
            app.get_accels_for_action (zoom_larger_button.action_name),
            _("Expand Window")
        );

        var cell_size_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            homogeneous = true,
            hexpand = true,
            margin_end = 6,
            margin_start = 6
        };
        cell_size_button_box.add_css_class (Granite.STYLE_CLASS_LINKED);
        cell_size_button_box.append (zoom_smaller_button);
        cell_size_button_box.append (zoom_default_button);
        cell_size_button_box.append (zoom_larger_button);

        var cell_size_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        cell_size_box.append (new Gtk.Label (_("Window size")));
        cell_size_box.append (cell_size_button_box);

        var load_game_button = new PopoverButton (_("Load"), ACTION_PREFIX + ACTION_OPEN);
        var save_game_button = new PopoverButton (_("Save"), ACTION_PREFIX + ACTION_SAVE);
        var save_as_game_button = new PopoverButton (_("Save to Different File"), ACTION_PREFIX + ACTION_SAVE_AS);
        var preferences_button = new PopoverButton (_("Preferences"), ACTION_PREFIX + ACTION_PREFERENCES);
        var solve_button = new PopoverButton (_("Solve"), ACTION_PREFIX + ACTION_SOLVE);

        var shortcut_button = new PopoverButton (_("Keyboard Shortcuts"), ACTION_PREFIX + ACTION_SHORTCUT_WINDOW);
        var about_button = new PopoverButton (_("About Gnonograms"), ACTION_PREFIX + ACTION_ABOUT_WINDOW);

        var settings_box = new Gtk.Box (VERTICAL, 3) {
            margin_start = 12,
            margin_end = 12,
        };
        settings_box.append (title_entry);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (cell_size_box);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (load_game_button);
        settings_box.append (save_game_button);
        settings_box.append (save_as_game_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (solve_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (preferences_button);
        settings_box.append (shortcut_button);
        settings_box.append (about_button);

        child = settings_box;
    }
}
