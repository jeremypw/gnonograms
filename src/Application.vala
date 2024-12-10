/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms {
    public enum GameState {
        SETTING,
        SOLVING,
        GENERATING,
        LOAD_SAVE;
    }

    public const string ACTION_GROUP = "win";
    public const string ACTION_PREFIX = ACTION_GROUP + ".";
    public const string ACTION_UNDO = "action-undo";
    public const string ACTION_REDO = "action-redo";
    // public const string ACTION_ZOOM_IN = "action-zoom-in";
    // public const string ACTION_ZOOM_OUT = "action-zoom-out";
    public const string ACTION_CURSOR_UP = "action-cursor_up";
    public const string ACTION_CURSOR_DOWN = "action-cursor_down";
    public const string ACTION_CURSOR_LEFT = "action-cursor_left";
    public const string ACTION_CURSOR_RIGHT = "action-cursor_right";
    public const string ACTION_SETTING_MODE = "action-setting-mode";
    public const string ACTION_SOLVING_MODE = "action-solving-mode";
    public const string ACTION_GENERATING_MODE = "action-generating-mode";
    public const string ACTION_OPEN = "action-open";
    public const string ACTION_SAVE = "action-save";
    public const string ACTION_SAVE_AS = "action-save-as";
    public const string ACTION_CHECK_ERRORS = "action-check-errors";
    public const string ACTION_RESTART = "action-restart";
    public const string ACTION_COMPUTER_SOLVE = "action-solve";
    public const string ACTION_HINT = "action-hint";
    public const string ACTION_OPTIONS = "action-options";
    public const string ACTION_OPTIONS_ACCEL = "";
    public const string ACTION_ZOOM_SMALLER = "action-zoom-smaller";
    public const string ACTION_ZOOM_DEFAULT = "action-zoom-default";
    public const string ACTION_ZOOM_LARGER = "action-zoom-larger";
    public const string ACTION_SHORTCUT_WINDOW = "action-shortcut-window";
    public const string ACTION_ABOUT_WINDOW = "action-about-dialog";
    public const string ACTION_PREFERENCES = "action-preferences";

#if WITH_DEBUGGING
    public const string ACTION_DEBUG_ROW = "action-debug-row";
    public const string ACTION_DEBUG_COL = "action-debug-col";
#endif
    public GLib.Settings saved_state;
    public GLib.Settings settings;



    public class App : Gtk.Application {
    private Controller controller;

    public signal void game_state_changed (GameState gs);
    public signal void dimensions_changed (uint rows, uint cols);

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
        warning ("quit action");
            if (controller != null) {
                controller.on_delete_request (); /* Will save state */
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
            // controller.quit_app.connect (quit);
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
