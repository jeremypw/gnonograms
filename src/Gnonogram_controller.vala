/* Controller class for Gnonograms3
 * Copyright (C) 2010-2011  Jeremy Wootten
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
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */
namespace Gnonograms {
public class Controller : GLib.Object {
    private View gnonogram_view;
    private CellGrid cell_grid;
    private LabelBox row_clue_box;
    private LabelBox column_clue_box;
    private Model model;
    private GameState game_state;
    private Cell current_cell;
    private Cell previous_cell;

    public string game_path {get; set;}
    public Dimensions dimensions {get; set;}

    public Gtk.Window window {
        get {
            return (Gtk.Window)gnonogram_view;
        }
    }

    construct {
        initialize_cursor ();
    }

    public Controller (Dimensions dimensions) {
        Object (dimensions: dimensions);

        create_view (dimensions);
        reset_all_to_default ();
        new_game ();
    }

    private void create_view (Dimensions dimensions) {
        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, dimensions);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, dimensions);
        cell_grid = new CellGrid (dimensions);
        model = new Model (dimensions);
        gnonogram_view = new Gnonograms.View (row_clue_box, column_clue_box, cell_grid);
        gnonogram_view.show_all();
    }

    public void new_game () {
        model.clear ();
        model.fill_random (7);
        initialize_view ();
        /* For testing */
        change_game_state (GameState.SETTING);
    }

    private void initialize_view () {
        initialize_cursor ();
    }

    private void initialize_cursor () {
        current_cell = { -1, -1, CellState.UNKNOWN};
        previous_cell = { -1, -1, CellState.UNKNOWN};
    }

    private void change_game_state (GameState gs) {
        initialize_cursor ();
        game_state = gs;

        if (gs == GameState.SETTING) {
             model.display_solution ();
        } else {
            model.display_working ();
        }

        cell_grid.array = model.display_data;
    }

    private void reset_all_to_default () {
    }

    private void save_game_state () {
    }

    public void quit () {
        save_game_state ();
    }
}
}
