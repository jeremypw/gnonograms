/* Game file reader class for gnonograms-elementary
 * Copyright (C) 2010-2017  Jeremy Wootten
 *
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 *  Jeremy Wootten  < jeremwootten@gmail.com >
 */

namespace Gnonograms {
public class Filewriter : Object {

    public string? game_path {get; set;}
    public string name {get; construct;}
    public uint rows {get; construct;}
    public uint cols {get; construct;}
    public string[] row_clues {get; construct;}
    public string[] col_clues {get; construct;}

    /* Optional properties */
    public string author {get; set; default = "";}
    public DateTime date {get; set;}
    public string license {get; set; default = "";}
    public Difficulty difficulty {get; set; default = Difficulty.UNDEFINED;}
    public My2DCellArray? solution {get; set; default = null;}
    public My2DCellArray? working {get; set; default = null;}
    public GameState game_state {get; set; default = GameState.UNDEFINED;}

    private FileStream? stream;

    public Filewriter (Gtk.Window? parent,
                       string? path,
                       string name,
                       uint rows,
                       uint cols,
                       string[] row_clues,
                       string[] col_clues) throws IOError {

        Object (name: name,
                rows: rows,
                cols: cols,
                row_clues: row_clues,
                col_clues: col_clues);

        if (path == null || path.length <= 4) {
            game_path = Utils.get_save_file_path ();
        } else {
            game_path = path;
        }

        if (game_path == "") {
            throw new IOError.CANCELLED ("No path selected");
        }

        if (game_path.length < 4 || game_path[-4 : game_path.length] != Gnonograms.GAMEFILEEXTENSION){
            game_path = game_path + Gnonograms.GAMEFILEEXTENSION;
        }

        stream = FileStream.open (game_path, "w");

        if (stream == null) {
            throw new IOError.FAILED ("Could not open filestream to %s".printf (game_path));
        }
    }

    construct {
        date = new DateTime.now_local ();
    }

    public void write_game_file () throws IOError {
        if (name == null || name.length == 0) {
            throw new IOError.NOT_INITIALIZED ("No name to save");
        }

        stream.printf ("[Description]\n");
        stream.printf ("%s\n", name);
        stream.printf ("%s\n", author);
        stream.printf ("%s\n", date.to_string ());
        stream.printf ("%s\n", difficulty.to_string ());

        if (license == null || license.length > 0) {
            stream.printf("[License]\n");
            stream.printf("%s\n", license);
        }

        if (rows == 0 || cols == 0) {
            throw new IOError.NOT_INITIALIZED ("No dimensions to save");
        }

        stream.printf("[Dimensions]\n");
        stream.printf("%u\n", rows);
        stream.printf("%u\n", cols);

        if (row_clues.length == 0 || col_clues.length == 0) {
            throw new IOError.NOT_INITIALIZED ("No clues to save");
        }

        if (row_clues.length != rows || col_clues.length != cols) {
            throw new IOError.NOT_INITIALIZED ("Clues do not match dimensions");
        }

        stream.printf("[Row clues]\n");
        foreach (string s in row_clues) {
            stream.printf("%s\n", s);
        }

        stream.printf("[Column clues]\n");
        foreach (string s in col_clues) {
            stream.printf("%s\n", s);
        }

        stream.flush();
    }

    public void write_position_file () throws IOError {
        if (working == null) {
            throw (new IOError.NOT_INITIALIZED ("No working grid to save"));
        } else if (solution == null) {
            throw (new IOError.NOT_INITIALIZED ("No solution grid to save"));
        } else if (game_state == GameState.UNDEFINED) {
            throw (new IOError.NOT_INITIALIZED ("No game state to save"));
        }

        write_game_file ();

        stream.printf ("[Solution grid]\n");
        stream.printf (solution.to_string ());
        stream.printf ("[Working grid]\n");
        stream.printf (working.to_string());
        stream.printf ("[State]\n");
        stream.printf (game_state.to_string() + "\n");
        stream.flush ();
    }
}
}
