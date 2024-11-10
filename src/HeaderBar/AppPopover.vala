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
        var title_entry = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here"),
            margin_top = 12,
        };

        var load_game_button = new PopoverButton (_("Load"), ACTION_PREFIX + ACTION_OPEN);
        var save_game_button = new PopoverButton (_("Save"), ACTION_PREFIX + ACTION_SAVE);
        var save_as_game_button = new PopoverButton (_("Save to Different File"), ACTION_PREFIX + ACTION_SAVE_AS);
        var preferences_button = new PopoverButton (_("Preferences"), ACTION_PREFIX + ACTION_PREFERENCES);
        var solve_button = new PopoverButton (_("Solve"), ACTION_PREFIX + ACTION_SOLVE);

        var settings_box = new Gtk.Box (VERTICAL, 3);
        settings_box.append (title_entry);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (load_game_button);
        settings_box.append (save_game_button);
        settings_box.append (save_as_game_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (solve_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (preferences_button);

        child = settings_box;
    }

    private class PopoverButton : Gtk.Button {
        public string text { get; construct; }
        public string detailed_action { get; construct; }

        public PopoverButton (string _text, string? _action_name = null) {
            Object (
                text: _text,
                detailed_action: _action_name // Assigning directly to Gtk.Button.action_name doesnt work for some reason
            );
        }

        construct {
            margin_top = 3;
            margin_bottom = 3;
            add_css_class (Granite.STYLE_CLASS_FLAT);
            set_action_name (detailed_action);
            if (text != null && detailed_action != null) {
                var accels = ((Gtk.Application) Application.get_default ()).get_accels_for_action (detailed_action);
                if (accels != null) {
                warning ("got accels");
                    child = new Granite.AccelLabel (text, accels[0]);
                    return;
                } else {
                    warning ("No accels for %s", detailed_action);
                }
            }

            warning ("fallback");
            child = new Gtk.Label (text);
        }
    }
}
