/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms {
    public GLib.Settings saved_state;
    public GLib.Settings settings;

public class App : Gtk.Application {
    private Controller controller;

    public App () {
        Object (
            application_id: Config.APP_ID,
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (Config.GETTEXT_PACKAGE);

        saved_state = new GLib.Settings (Config.APP_ID + ".saved-state");
        settings = new GLib.Settings (Config.APP_ID + ".settings");

        SimpleAction quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (controller != null) {
                controller.quit (); /* Will save state */
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Ctrl>q"});


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
}
