/* Entry point for gnonograms-elementary  - initialises application and launches game
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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {

public const Cell NULL_CELL = {uint.MAX, uint.MAX, CellState.UNDEFINED};
public static int MAXSIZE = 50; // max number rows or columns
public static int MINSIZE = 5; // Change to 1 when debugging
public static double MINFONTSIZE = 3.0;
public static double MAXFONTSIZE = 72.0;
public static int FAILED_PASSES = 999999;
public const string BLOCKSEPARATOR = ", ";
public const string BLANKLABELTEXT = _("?");
public const string GAMEFILEEXTENSION = ".gno";
public const string UNSAVED_FILENAME = "Unsaved Game" + GAMEFILEEXTENSION;


public class App : Granite.Application {
    public Controller controller;
    private string game_name;
    public string load_game_dir;
    public string save_game_dir;

    construct {
        application_id = "com.github.jeremypw.gnonograms-elementary";
        flags = ApplicationFlags.HANDLES_OPEN;

        program_name = _("Gnonograms");
        app_years = "2017";
        app_icon = "gnonograms-elementary";

        build_data_dir = Build.DATADIR;
        build_pkg_data_dir = Build.PKGDATADIR;
        build_release_name = Build.RELEASE_NAME;
        build_version = Build.VERSION;
        build_version_info = Build.VERSION_INFO;

        app_launcher = "com.github.jeremypw.gnonograms-elementary.desktop";
        main_url = "https://github.com/jeremypw/gnonograms-elementary";
        bug_url = "https://github.com/jeremypw/gnonograms-elementary/issues";
        help_url = "";
        translate_url = "";
        about_authors = { "Jeremy Wootten <jeremywootten@gmail.com" };
        about_comments = "";
        about_translators = _("translator-credits");
        about_license_type = Gtk.License.GPL_3_0;

        SimpleAction quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (controller != null) {
                controller.quit (); /* Will save state */
            }
        });

        add_action (quit_action);
        add_accelerator ("<Ctrl>q", "app.quit", null);

        game_name = "";
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
            game_name = fname;
            /* TODO retrieve data from game */
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

public static int main (string[] args) {
    var app = new Gnonograms.App ();
    return app.run (args);
}
