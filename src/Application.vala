/* Entry point for gnonograms  - initializes application and launches game
 * Copyright (C) 2010-2017  Jeremy Wootten
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
 *  Author:
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */

namespace Gnonograms {
public class App : Gtk.Application {
    public Controller controller;

    construct {
        application_id = Gnonograms.APP_ID;
        flags = ApplicationFlags.HANDLES_OPEN;

        SimpleAction quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (controller != null) {
                controller.quit (); /* Will save state */
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Ctrl>q"});
    }

    public override void startup () {
        base.startup ();
    }

    public override void open (File[] files, string hint) {
        /* Only one game can be played at a time */
        var file = files[0];

        if (file == null) {
            return;
        }

        var fname = file.get_basename ();

        if (fname.has_suffix (".gno")) {
            open_file (file);
        } else {
            activate ();
        }
    }

    public void open_file (File? game) {
        controller = new Controller (game);
        this.add_window (controller.window);

        controller.quit_app.connect (quit);
    }

    public override void activate () {
        open_file (null);
    }
}

public static App get_app () {
    return Application.get_default () as App;
}
}

private static bool version = false;

private const GLib.OptionEntry[] options = {
    // --version
    { "version", 0, 0, OptionArg.NONE, ref version, N_("Easy"), null },

    // list terminator
    { null }
};

public static int main (string[] args) {
    try {
        var opt_context = new OptionContext (N_("[Gnonogram Puzzle File (.gno)]"));
        opt_context.set_translation_domain (Gnonograms.APP_ID);
        opt_context.add_main_entries (options, Gnonograms.APP_ID);
        opt_context.add_group (Gtk.get_option_group (true));
        opt_context.parse (ref args);
    } catch (OptionError e) {
        printerr ("error: %s\n", e.message);
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    if (version) {
        print (Gnonograms.VERSION + "\n");
        return 0;
    }

    var app = new Gnonograms.App ();
    return app.run (args);
}
