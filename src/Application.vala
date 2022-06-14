/* Application.vala
 * Copyright (C) 2010-2021  Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.App : Gtk.Application {
    private Controller controller;

    public App () {
        Object (
            application_id: "com.github.jeremypw.gnonograms",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (Config.GETTEXT_PACKAGE);

        SimpleAction quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (controller != null) {
                controller.quit (); /* Will save state */
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Ctrl>q"});

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });
    }

    public override void open (File[] files, string hint) {
        /* Only one game can be played at a time */
        var file = files[0];
        activate ();
        if (file != null && file.get_basename ().has_suffix (".gno")) {
            controller.load_game (file);
        }
    }

    public override void activate () {
        if (controller == null) {
            controller = new Controller ();
            controller.quit_app.connect (quit);
            add_window (controller.window);
        } else {
            controller.window.present ();
        }
    }
}

private static bool version = false;

private const GLib.OptionEntry[] OPTIONS = {
    { "version", '\0', 0, OptionArg.NONE, ref version, N_("Show the version of the program"), null },
    { null }
};

public static int main (string[] args) {
    try {
        var opt_context = new OptionContext (N_("[Gnonogram Puzzle File (.gno)]"));
        opt_context.set_translation_domain (Config.APP_ID);
        opt_context.add_main_entries (OPTIONS, Config.APP_ID);
        opt_context.add_group (Gtk.get_option_group (true));
        opt_context.parse (ref args);
    } catch (OptionError e) {
        printerr ("error: %s\n", e.message);
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    if (version) {
        print (Config.VERSION + "\n");
        return 0;
    }

    var app = new Gnonograms.App ();
    return app.run (args);
}
