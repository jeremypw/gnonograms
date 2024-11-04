/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.AppPopover : Gtk.Popover {
    private Gtk.SpinButton row_setting;
    private Gtk.SpinButton column_setting;
    private Gtk.Entry title_setting;
    private Gtk.ColorDialogButton filled_color_setting;
    private Gtk.ColorDialogButton empty_color_setting;

    public Difficulty grade { get; set; }
    public string filled_color { get; set; }
    public string empty_color { get; set; }


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
            controller.decrease_fontsize ();
        });

        var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic");
        zoom_in_button.tooltip_markup = Granite.markup_accel_tooltip (
            {"<Ctrl>plus"},
            _("Zoom In")
        );
        zoom_in_button.clicked.connect (() => {
            controller.increase_fontsize ();
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
        font_size_box.append (zoom_in_button);

        var title_entry = new Gtk.Entry () {
            placeholder_text = _("Enter title of game here"),
            margin_top = 12,
        };

        var preferences_button = new Gtk.Button () {
            margin_top = 3,
            margin_bottom = 3
        };
        preferences_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        preferences_button.child = new Gtk.Label (_("Preferences")) {
            xalign = 0.0f
        };
        preferences_button.clicked.connect (() => {
            popdown ();
            var dialog = new Dialogs.Preferences ((Gtk.Window)get_ancestor (typeof (Gtk.Window)));
            dialog.response.connect (() => {
                dialog.destroy ();
            });
            dialog.present ();
        });

        var menu_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6
        };

        var settings_box = new Gtk.Box (VERTICAL, 0);
        settings_box.append (font_size_box);
        settings_box.append (title_entry);
        settings_box.append (menu_separator);
        settings_box.append (preferences_button);

        child = settings_box;
    }
}
