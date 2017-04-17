/* Controller class for gnonograms-elementary
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
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

    public File? game {get; set;}
    public Dimensions dimensions {get; set;}

    private double _fontheight;
    public double fontheight {
        set {
            _fontheight = value;
            row_clue_box.fontheight = value;
            column_clue_box.fontheight = value;
        }

        get {
            return _fontheight;
        }
    }

    public Gtk.Window window {
        get {
            return (Gtk.Window)gnonogram_view;
        }
    }

    construct {
        if (Granite.Services.Logger.DisplayLevel != Granite.Services.LogLevel.DEBUG) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        }

        initialize_cursor ();
    }

    public Controller (File? game = null) {
        Object (game: game);

        restore_settings ();
        model = new Model (dimensions);
        create_view (dimensions);

        if (game == null || !load_game (game)) {
            new_game ();
        }
    }

    private void create_view (Dimensions dimensions) {
        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, dimensions);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, dimensions);
        cell_grid = new CellGrid (dimensions);

        gnonogram_view = new Gnonograms.View (row_clue_box, column_clue_box, cell_grid);
        gnonogram_view.show_all();
    }

    public void new_game () {
        model.fill_random (7);
        initialize_view ();
        /* For testing */
        change_game_state (game_state);
    }

    private void initialize_view () {
        initialize_cursor ();
        set_fontheight_from_dimensions (dimensions);
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

    private void set_fontheight_from_dimensions (Dimensions dimensions) {
        assert (row_clue_box != null && column_clue_box != null);

        double max_h, max_w;
        var scr = Gdk.Screen.get_default();

        max_h = (double)(scr.get_height()) / ((double)(dimensions.height));
        max_w = (double)(scr.get_width()) / ((double)(dimensions.width));

        fontheight = double.min (max_h, max_w) / 4;
    }

    private void reset_all_to_default () {
    }

    private void save_game_state () {
    }

    private void restore_settings () {
        game_state = GameState.SETTING;
        dimensions = {10, 15}; /* TODO implement saving and restoring settings */
    }

    private bool load_game (File game) {
        game_state = GameState.SOLVING;
        dimensions = {10, 15}; /* TODO implement saving and restoring settings */
        return true;
    }

    public void quit () {
        save_game_state ();
    }
}
}
