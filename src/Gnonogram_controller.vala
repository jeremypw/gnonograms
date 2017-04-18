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
    private int rows {get { return dimensions.height; }}
    private int cols {get { return dimensions.width; }}

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
        connect_signals ();

        if (game == null || !load_game (game)) {
            new_game ();
        }
    }

    private void create_view (Dimensions dimensions) {
        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, dimensions);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, dimensions);
        cell_grid = new CellGrid (model.display_data);

        gnonogram_view = new Gnonograms.View (row_clue_box, column_clue_box, cell_grid);
        gnonogram_view.show_all();
    }

    private void connect_signals () {
        cell_grid.cursor_moved.connect (on_grid_cursor_moved);
    }

    private void new_game () {
        model.fill_random (7);
        initialize_view ();
        update_labels_from_model ();
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
    }

    private void set_fontheight_from_dimensions (Dimensions dimensions) {
        assert (row_clue_box != null && column_clue_box != null);

        double max_h, max_w;
        var scr = Gdk.Screen.get_default();

        max_h = (double)(scr.get_height()) / ((double)(dimensions.height));
        max_w = (double)(scr.get_width()) / ((double)(dimensions.width));

        fontheight = double.min (max_h, max_w) / 4;
    }

    private void save_game_state () {
    }

    private void restore_settings () {
        game_state = GameState.SETTING;
        dimensions = {30, 10}; /* TODO implement saving and restoring settings */
    }

    private bool load_game (File game) {
        game_state = GameState.SOLVING;
        new_game ();  /* TODO implement saving and restoring settings */
        return true;
    }

    private void update_labels_from_model () {
        for (int r = 0; r < rows; r++) {
            row_clue_box.update_label (r, model.get_label_text (r, false));
        }

        for (int c = 0; c < cols; c++) {
            column_clue_box.update_label (c, model.get_label_text (c, true));
        }
    }

    private void highlight_labels_and_cell(Cell c, bool is_highlight)
    {
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

/*** Signal Handlers ***/

    private void on_grid_cursor_moved (int r, int c) {
        if (r<0||r>=rows||c<0||c>=cols)//pointer has left grid
        {
            highlight_labels_and_cell (previous_cell,false);
            highlight_labels_and_cell (current_cell,false);
            current_cell.row=-1;
            return;
        }

        previous_cell.copy(current_cell);
        if (current_cell.row != r || current_cell.col != c)
        {
            highlight_labels_and_cell (previous_cell, false);

            current_cell = model.get_cell (r, c);
            highlight_labels_and_cell (current_cell, true);
        }
    }

    public void quit () {
        save_game_state ();
    }
}
}
