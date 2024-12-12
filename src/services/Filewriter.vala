/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.Filewriter : Object {
    public DateTime date { get; construct; }
    public Gtk.Window? parent { get; construct; }
    public Difficulty difficulty { get; set; default = Difficulty.UNDEFINED;}
    public My2DCellArray? solution { get; set; default = null;}
    public uint rows { get; construct; }
    public uint cols { get; construct; }
    public string[] row_clues { get; construct; }
    public string[] col_clues { get; construct; }
    public string? game_path { get; set construct; }
    public string? save_to_path { get; set construct; }
    public string? game_name { get; set construct; }
    public string? save_dir_path { get; construct; }
    public string author { get; set; default = "";}
    public string license { get; set; default = "";}
    private FileStream? stream;

    public Filewriter (
        Gtk.Window? parent,
        Dimensions dimensions,
        string[] row_clues,
        string[] col_clues,
        Difficulty difficulty,
        string? save_dir_path,
        string? game_path,
        string game_name,
        string? save_to_path
    ) {

        Object (
            parent: parent,
            rows: dimensions.height,
            cols: dimensions.width,
            row_clues: row_clues,
            col_clues: col_clues,
            difficulty: difficulty,
            save_dir_path: save_dir_path,
            game_path: game_path,
            game_name: game_name,
            save_to_path: save_to_path
        );
    }

    construct {
        date = new DateTime.now_local ();
    }

    /*** Writes minimum information required for valid game file ***/
    public async void write_game_file (SaveFlags flags) throws Error {
        if (game_name == null) {
           game_name = _(UNTITLED_NAME);
        }

        if (save_to_path == null || save_to_path.length <= 4) {
            var save_to_file = yield Utils.get_open_save_file (
                parent,
                _("Name and save this puzzle"),
                true,
                save_dir_path,
                game_name
            );

            if (save_to_file != null) {
                save_to_path = save_to_file.get_path ();
            }
        }

        if (save_to_path != null &&
            (save_to_path.length < 4 ||
             save_to_path[-4 : save_to_path.length] != Gnonograms.GAMEFILEEXTENSION)) {

            save_to_path = save_to_path + Gnonograms.GAMEFILEEXTENSION;
        }

        if (save_to_path == null) {
            throw new IOError.CANCELLED ("No save path selected");
        }

        var file = File.new_for_commandline_arg (save_to_path);
        if (CONFIRM_OVERWRITE in flags &&
            file.query_exists ()) {
            var overwrite = Utils.show_confirm_dialog (
                _("Overwrite %s").printf (save_to_path),
                _("This action will destroy contents of that file"),
                parent
            );

            if (!overwrite) {
                throw new IOError.CANCELLED ("File exists");
            }
        }

        /* @game_path is local path, not a uri */
        stream = FileStream.open (save_to_path, "w");
        if (stream == null) {
            throw new IOError.FAILED ("Could not open filestream to %s".printf (save_to_path));
        }

        stream.printf ("[Description]\n");
        stream.printf ("%s\n", game_name);
        stream.printf ("%s\n", author != "" ? author : "Gnonograms Generator");
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

        if (solution != null) {
            stream.printf ("[Solution grid]\n");
            stream.printf ("%s", solution.to_string ());
        }
    }

    /*** Writes complete information to reload game state ***/
    public async void write_position_file (
        My2DCellArray working,
        GameState state,
        History history
    ) throws Error {
        yield write_game_file (SaveFlags.NONE);

        stream.printf ("[Working grid]\n");
        stream.printf (working.to_string ());
        stream.printf ("[State]\n");
        stream.printf (state.to_string () + "\n");
        stream.printf ("[Original path]\n");
        stream.printf (game_path.to_string () + "\n");

        if (history != null) {
            stream.printf ("[History]\n");
            stream.printf (history.to_string () + "\n");
        }

        stream.flush ();
    }
}
