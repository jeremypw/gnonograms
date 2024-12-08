/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.Filewriter : Object {
    public DateTime date { get; construct; }
    public History? history { get; construct; }
    public Gtk.Window? parent { get; construct; }
    public Difficulty difficulty { get; set; default = Difficulty.UNDEFINED;}
    public GameState game_state { get; set; default = GameState.UNDEFINED;}
    public My2DCellArray? solution { get; set; default = null;}
    public My2DCellArray? working { get; set; default = null;}
    public uint rows { get; construct; }
    public uint cols { get; construct; }
    public string name { get; set; }
    public string[] row_clues { get; construct; }
    public string[] col_clues { get; construct; }
    public bool save_solution { get; construct; }
    public string? game_path { get; private set; }
    public string author { get; set; default = "";}
    public string license { get; set; default = "";}
    public bool is_readonly { get; set; default = true;}


    private FileStream? stream;

    public Filewriter (Gtk.Window? parent,
                       Dimensions dimensions,
                       string[] row_clues,
                       string[] col_clues,
                       History? history,
                       bool save_solution) {

        Object (
            name: _(UNTITLED_NAME),
            parent: parent,
            rows: dimensions.height,
            cols: dimensions.width,
            row_clues: row_clues,
            col_clues: col_clues,
            history: history,
            save_solution: save_solution
        );
    }

    construct {
        date = new DateTime.now_local ();
    }

    /*** Writes minimum information required for valid game file ***/
    public async void write_game_file (
        string? save_dir_path = null,
        string? path = null,
        string? _name = null
    ) throws Error {
        if (_name != null) {
            name = _name;
        } else {
            name = _(UNTITLED_NAME);
        }

        if (path == null || path.length <= 4) {
            var game_file = yield Utils.get_open_save_file (parent,
                _("Name and save this puzzle"),
                true,
                save_dir_path,
                name
            );

            if (game_file != null) {
                game_path = game_file.get_path ();
            }
        } else {
            game_path = path;
        }

        if (game_path != null &&
            (game_path.length < 4 ||
             game_path[-4 : game_path.length] != Gnonograms.GAMEFILEEXTENSION)) {

            game_path = game_path + Gnonograms.GAMEFILEEXTENSION;
        }

        if (game_path == null) {
            throw new IOError.CANCELLED ("No path selected");
        }

        var file = File.new_for_commandline_arg (game_path);
        if (file.query_exists () &&
            !Utils.show_confirm_dialog (
                _("Overwrite %s").printf (game_path),
                _("This action will destroy contents of that file"))
        ) {
            throw new IOError.CANCELLED ("File exists");
        }

        /* @game_path is local path, not a uri */
        stream = FileStream.open (game_path, "w");
        if (stream == null) {
            throw new IOError.FAILED ("Could not open filestream to %s".printf (game_path));
        }

        if (name == null || name.length == 0) {
            throw new IOError.NOT_INITIALIZED ("No name to save");
        }

        stream.printf ("[Description]\n");
        stream.printf ("%s\n", name);
        stream.printf ("%s\n", author);
        stream.printf ("%s\n", date.to_string ());
        stream.printf ("%u\n", difficulty);

        if (license == null || license.length > 0) {
            stream.printf ("[License]\n");
            stream.printf ("%s\n", license);
        }

        if (rows == 0 || cols == 0) {
            throw new IOError.NOT_INITIALIZED ("No dimensions to save");
        }

        stream.printf ("[Dimensions]\n");
        stream.printf ("%u\n", rows);
        stream.printf ("%u\n", cols);

        if (row_clues.length == 0 || col_clues.length == 0) {
            throw new IOError.NOT_INITIALIZED ("No clues to save");
        }

        if (row_clues.length != rows || col_clues.length != cols) {
            throw new IOError.NOT_INITIALIZED ("Clues do not match dimensions");
        }

        stream.printf ("[Row clues]\n");
        foreach (string s in row_clues) {
            stream.printf ("%s\n", s);
        }

        stream.printf ("[Column clues]\n");
        foreach (string s in col_clues) {
            stream.printf ("%s\n", s);
        }

        stream.flush ();

        if (solution != null && save_solution) {
            stream.printf ("[Solution grid]\n");
            stream.printf ("%s", solution.to_string ());
        }

        stream.printf ("[Locked]\n");
        stream.printf (is_readonly.to_string () + "\n");
    }

    /*** Writes complete information to reload game state ***/
    public async void write_position_file (string? save_dir_path = null,
                                     string? path = null,
                                     string? name = null) throws Error {
        if (working == null) {
            throw (new IOError.NOT_INITIALIZED ("No working grid to save"));
        } else if (game_state == GameState.UNDEFINED) {
            throw (new IOError.NOT_INITIALIZED ("No game state to save"));
        }

        yield write_game_file (save_dir_path, path, name );
        stream.printf ("[Working grid]\n");
        stream.printf (working.to_string ());
        stream.printf ("[State]\n");
        stream.printf (game_state.to_string () + "\n");

        if (name != _(UNTITLED_NAME)) {
            stream.printf ("[Original path]\n");
            stream.printf (game_path.to_string () + "\n");
        }

        if (history != null) {
            stream.printf ("[History]\n");
            stream.printf (history.to_string () + "\n");
        }

        stream.flush ();
    }
}
