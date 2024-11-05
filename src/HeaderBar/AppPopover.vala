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
        var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic");
        zoom_out_button.tooltip_markup = Granite.markup_accel_tooltip (
            {"<Ctrl>minus"},
            _("Zoom Out")
        );
        zoom_out_button.clicked.connect (() => {
            var current_font_scale = settings.get_int ("font-scaling");
            settings.set_int ("font-scaling", current_font_scale - 10);
        });

        var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic");
        zoom_in_button.tooltip_markup = Granite.markup_accel_tooltip (
            {"<Ctrl>plus"},
            _("Zoom In")
        );
        zoom_in_button.clicked.connect (() => {
            var current_font_scale = settings.get_int ("font-scaling");
            settings.set_int ("font-scaling", current_font_scale + 10);
        });

        var zoom_default_button = new Gtk.Button () {
            label = settings.get_int ("font-scaling").to_string () + "%"
        };

        zoom_default_button.tooltip_markup = Granite.markup_accel_tooltip (
            {"<Ctrl>0"},
            _("Zoom Default")
        );
        zoom_default_button.clicked.connect (() => {
            var current_font_scale = settings.get_int ("font-scaling");
            settings.set_int ("font-scaling", 100);
        });
        settings.changed["font-scaling"].connect (() => {
            zoom_default_button.label = settings.get_int ("font-scaling").to_string () + "%";
        });

        var font_size_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            homogeneous = true,
            hexpand = true,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
        };
        font_size_box.add_css_class (Granite.STYLE_CLASS_LINKED);
        font_size_box.append (zoom_out_button);
        font_size_box.append (zoom_default_button);
        font_size_box.append (zoom_in_button);

        var title_entry = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here"),
            margin_top = 12,
        };

        var load_game_button = new PopoverButton (_("Load"), ACTION_PREFIX + ACTION_OPEN);
        var save_game_button = new PopoverButton (_("Save"), ACTION_PREFIX + ACTION_SAVE);
        var save_as_game_button = new PopoverButton (_("Save to Different File"), ACTION_PREFIX + ACTION_SAVE_AS);
        var preferences_button = new PopoverButton (_("Preferences"));

        preferences_button.clicked.connect (() => {
            popdown ();
            var dialog = new Dialogs.Preferences ((Gtk.Window)get_ancestor (typeof (Gtk.Window)));
            dialog.response.connect (() => {
                dialog.destroy ();
            });
            dialog.present ();
        });

        var settings_box = new Gtk.Box (VERTICAL, 3);
        settings_box.append (font_size_box);
        settings_box.append (title_entry);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (load_game_button);
        settings_box.append (save_game_button);
        settings_box.append (save_as_game_button);
        settings_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        settings_box.append (preferences_button);

        child = settings_box;
    }

    private class PopoverButton : Gtk.Button {
        public PopoverButton (string label, string? action_name = null) {
            Object (
                child: new Gtk.Label (label) {xalign = 0.0f},
                action_name: action_name
            );
        }

        construct {
            margin_top = 3;
            margin_bottom = 3;
            add_css_class (Granite.STYLE_CLASS_FLAT);
        }
    }
}
