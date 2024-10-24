/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.AppPopover : Gtk.Popover {
    public signal void apply_settings ();

    private Gtk.DropDown grade_setting;
    private Gtk.SpinButton row_setting;
    private Gtk.SpinButton column_setting;
    private Gtk.Entry title_setting;
    private Gtk.ColorDialogButton filled_color_setting;
    private Gtk.ColorDialogButton empty_color_setting;

    // public Difficulty grade {
    //     get {
    //         return (Difficulty) (grade_setting.get_selected ());
    //     }

    //     set {
    //         grade_setting.set_selected (
    //             ((uint) value).clamp (
    //                 MIN_GRADE,
    //                 Difficulty.MAXIMUM
    //             )
    //         );
    //     }
    // }

    // public uint rows {
    //     get {
    //         return (uint)(row_setting.@value);
    //     }

    //     set {
    //         row_setting.@value = value;
    //     }
    // }

    // public uint columns {
    //     get {
    //         return (uint)(column_setting.@value);
    //     }

    //     set {
    //         column_setting.@value = value;
    //     }
    // }

    // public string title {
    //     get {
    //         return title_setting.text;
    //     }

    //     set {
    //         title_setting.text = value;
    //     }
    // }

    public string filled_color { get; set; }
    public string empty_color { get; set; }


    public Controller controller { get; construct; }
    public AppPopover (Controller controller) {
        Object (
            controller: controller
        );
    }
    construct {
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

        var main_widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_widget.append (settings_grid);

        child = main_widget;

        // Could not get bind with mapping to work with RGBA property
        filled_color_setting.notify["rgba"].connect (() => {
            var color = filled_color_setting.get_rgba ();
            filled_color = color.to_string ();
        });
        notify["filled-color"].connect (() => {
            var color = Gdk.RGBA () {};
            color.parse (filled_color);
            filled_color_setting.set_rgba (color);
        });

        empty_color_setting.notify["rgba"].connect (() => {
            var color = empty_color_setting.get_rgba ();
            empty_color = color.to_string ();
        });
        notify["empty-color"].connect (() => {
            var color = Gdk.RGBA () {};
            color.parse (empty_color);
            empty_color_setting.set_rgba (color);
        });

        settings.bind ("grade", grade_setting, "selected", DEFAULT);
        settings.bind ("filled-color", this, "filled-color", DEFAULT);
        settings.bind ("empty-color", this, "empty-color", DEFAULT);
        settings.bind ("rows", this, "rows", DEFAULT);
        settings.bind ("columns", column_setting, "columns", DEFAULT);
        settings.bind ("rows", row_setting, "value", DEFAULT);
    }
}
