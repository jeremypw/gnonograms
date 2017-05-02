/* Controller class for gnonograms-elementary - creates model and view, handles user input and settings.
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
public class Controller : GLib.Object {
    private View gnonogram_view;
    private Gtk.HeaderBar? header_bar;
    private Granite.Widgets.ModeButton mode_switch;
    private DimensionControl size_changer;
    private HistoryControl history;

    private int setting_index;
    private int solving_index;

    private CellGrid cell_grid;
    private LabelBox row_clue_box;
    private LabelBox column_clue_box;
    private Model? model;

    private GameState _game_state;
    public GameState game_state {
        get {
            return _game_state;
        }

        private set {
            if (_game_state != value) {
                _game_state = value;

                set_mode_switch (value);
                initialize_cursor ();

                if (model != null && header_bar != null && cell_grid != null) {
                    cell_grid.game_state = value;
                    model.game_state = value;
                    if (value == GameState.SETTING) {
                        header_bar.subtitle = _("Setting");
                    } else {
                        header_bar.subtitle = _("Solving");
                    }
                }
            }
        }
    }
    private Cell current_cell;
    private Cell previous_cell;

    private File? _game;
    public File? game {
        get {
            return _game;
        }

        set {
            _game = value;
            if (value != null && header_bar != null) {
                header_bar.title = value.get_uri ();
            }
        }
    }

    private Dimensions _dimensions;
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            if (value != _dimensions) {
                _dimensions = value;

                /* Do not update during construction */
                if (row_clue_box != null) {
                    row_clue_box.dimensions = dimensions;
                    column_clue_box.dimensions = dimensions;
                }

                if (model != null) {
                    model.dimensions = dimensions;
                }
            }
        }
    }

    private uint rows {get { return dimensions.height; }}
    private uint cols {get { return dimensions.width; }}

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

    private CellState drawing_with_state;

    construct {
        if (Granite.Services.Logger.DisplayLevel != Granite.Services.LogLevel.DEBUG) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        }

        header_bar = new Gtk.HeaderBar ();
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        history = new HistoryControl ();
        header_bar.pack_start (history);

        mode_switch = new Granite.Widgets.ModeButton ();
        var setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU); /* provisional only */
        var solving_icon = new Gtk.Image.from_icon_name ("process-working-symbolic", Gtk.IconSize.MENU);  /* provisional only */

        setting_icon.set_data ("mode", GameState.SETTING);
        solving_icon.set_data ("mode", GameState.SOLVING);

        setting_index = mode_switch.append (setting_icon);
        solving_index = mode_switch.append (solving_icon);

        header_bar.pack_start (mode_switch);

        game_state = GameState.UNDEFINED;
        drawing_with_state = CellState.UNDEFINED;
    }

    public Controller (File? game = null) {
        Object (game: game);

        restore_settings ();
        create_view_and_model (dimensions);
        connect_signals ();
        initialize_view ();
        fontheight = get_default_fontheight_from_dimensions (dimensions);

        if (game == null || !load_game (game)) {
            new_game ();
        }
    }

    private void create_view_and_model (Dimensions dimensions) {
        model = new Model (dimensions);

        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, dimensions);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, dimensions);
        cell_grid = new CellGrid (model);
        size_changer = new DimensionControl (dimensions);
        header_bar.pack_end (size_changer);

        gnonogram_view = new Gnonograms.View (row_clue_box, column_clue_box, cell_grid);
        gnonogram_view.set_titlebar (header_bar);
        gnonogram_view.show_all();
    }

    private void connect_signals () {
        cell_grid.cursor_moved.connect (on_grid_cursor_moved);
        cell_grid.leave_notify_event.connect (on_grid_leave);
        cell_grid.button_press_event.connect (on_grid_button_press);
        cell_grid.button_release_event.connect (on_grid_button_release);

        mode_switch.mode_changed.connect (on_mode_switch_changed);

        size_changer.changed.connect (on_size_changer_changed);

        gnonogram_view.key_press_event.connect (on_view_key_press_event);
        gnonogram_view.key_release_event.connect (on_view_key_release_event);
    }

    private void new_game () {
        game_state = GameState.SETTING;
        model.blank_solution ();
        header_bar.set_title (_("Blank sheet"));
        initialize_view ();
        update_labels_from_model ();
    }

    private void new_random_game () {
        /* TODO  Check/confirm overwriting existing game */
        game_state = GameState.SOLVING;
        model.fill_random (4);
        header_bar.set_title (_("Random game"));
        initialize_view ();
        update_labels_from_model ();
    }

    private void initialize_view () {
        initialize_cursor ();
    }

    private void initialize_cursor () {
        current_cell = NULL_CELL;
        previous_cell = NULL_CELL;
    }

    private double get_default_fontheight_from_dimensions (Dimensions dimensions) {
        assert (row_clue_box != null && column_clue_box != null);

        double max_h, max_w;
        var scr = Gdk.Screen.get_default();

        max_h = (double)(scr.get_height()) / ((double)(dimensions.height * 2));
        max_w = (double)(scr.get_width()) / ((double)(dimensions.width * 2));

        return double.min (max_h, max_w) / 2.5;
    }

    private void save_game_state () {
    }

    private void restore_settings () {
        dimensions = {25, 15}; /* TODO implement saving and restoring settings */
    }

    private bool load_game (File game) {
        new_game ();  /* TODO implement saving and restoring settings */
        return true;
    }

    private void update_labels_from_model () {
        for (int r = 0; r < rows; r++) {
            row_clue_box.update_label_text (r, model.get_label_text (r, false));
        }

        for (int c = 0; c < cols; c++) {
            column_clue_box.update_label_text (c, model.get_label_text (c, true));
        }
    }

    private void update_labels_for_cell (Cell cell) {
        row_clue_box.update_label_text (cell.row, model.get_label_text (cell.row, false));
        column_clue_box.update_label_text (cell.col, model.get_label_text (cell.col, true));
    }

    private void highlight_labels (Cell c, bool is_highlight) {
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void set_mode_switch (GameState gs) {
        if (gs == GameState.SETTING) {
            mode_switch.set_active (setting_index);
        } else {
            mode_switch.set_active (solving_index);
        }
    }

    private void handle_arrow_keys (string keyname, uint mods) {
        int r = 0; int c = 0;
        switch (keyname) {
            case "UP":
                    r = -1;
                    break;
            case "DOWN":
                    r = 1;
                    break;
            case "LEFT":
                    c = -1;
                    break;
            case "RIGHT":
                    c = 1;
                    break;

            default:
                    return;
        }

        cell_grid.move_cursor_relative (r, c);
    }

    private void handle_pen_keys (string keyname, uint mods) {
        if (mods > 0) {
            return;
        }

        switch (keyname) {
            case "F":
                drawing_with_state = CellState.FILLED;
                break;

            case "E":
                drawing_with_state = CellState.EMPTY;
                break;

            case "X":
                if (game_state == GameState.SOLVING) {
                    drawing_with_state = CellState.UNKNOWN;
                    break;
                } else {
                    return;
                }

            default:
                    return;
        }

        mark_current_cell (drawing_with_state);
    }

    private void mark_current_cell (CellState state) {
        if (current_cell != NULL_CELL && current_cell.state != state) {
            current_cell.state = state;
            model.set_data_from_cell (current_cell);
            cell_grid.queue_draw ();


            if (game_state == GameState.SETTING) {
                update_labels_for_cell (current_cell);
            }
        }
    }

    private void resize_to (Dimensions new_dim) {
        /* Reduce font size if new grid would not fit on screen */
        var fh = get_default_fontheight_from_dimensions (dimensions);
        if (fh < fontheight) {
            fontheight = fh;
        }

        dimensions = new_dim;
        model.clear ();
        update_labels_from_model ();
        game_state = GameState.SETTING;
    }

/*** Signal Handlers ***/

    private void on_grid_cursor_moved (Cell cell) {
        highlight_labels (current_cell, false);
        highlight_labels (cell, true);
        current_cell.copy (cell);
        if (drawing_with_state != CellState.UNDEFINED) {
            mark_current_cell (drawing_with_state);
        }
    }

    private bool on_grid_leave () {
        highlight_labels (current_cell, false);
        current_cell = NULL_CELL;
        return false;
    }

    private bool on_view_key_press_event (Gdk.EventKey event) {
        if (event.is_modifier == 1) {
            return true;
        }

        var name = (Gdk.keyval_name (event.keyval)).up();
        var mods = (event.state & Gtk.accelerator_get_default_mod_mask ());
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
        bool other_mod_pressed = (((mods & ~Gdk.ModifierType.SHIFT_MASK) & ~Gdk.ModifierType.CONTROL_MASK) != 0);
        bool only_control_pressed = control_pressed && !other_mod_pressed; /* Shift can be pressed */
        switch (name) {
            case "UP":
            case "DOWN":
            case "LEFT":
            case "RIGHT":
                handle_arrow_keys (name, mods);
                break;

            case "F":
            case "E":
            case "X":
                handle_pen_keys (name, mods);
                break;

            case "1":
            case "2":
                if (only_control_pressed) {
                    game_state = name == "1" ? GameState.SETTING : GameState.SOLVING;
                }

                break;

            case "MINUS":
            case "EQUAL":
            case "PLUS":
                if (only_control_pressed) {
                    if (name == "MINUS") {
                        fontheight -= 1.0;
                    } else {
                        fontheight += 1.0;
                    }
                }

                break;

            case "R":
                if (only_control_pressed) {
                    new_random_game ();
                }

                break;

            default:
                return false;
        }
        return true;
    }

    private bool on_view_key_release_event (Gdk.EventKey event) {
        var name = (Gdk.keyval_name (event.keyval)).up();

        switch (name) {
            case "F":
            case "E":
            case "X":
                drawing_with_state = CellState.UNDEFINED;
                break;

            default:
                return false;
        }

        return true;
    }

    private bool on_grid_button_press (Gdk.EventButton event) {
        switch (event.button) {
            case Gdk.BUTTON_PRIMARY:
                drawing_with_state = CellState.FILLED;
                break;

            case Gdk.BUTTON_MIDDLE:
                if (game_state == GameState.SOLVING) {
                    drawing_with_state = CellState.UNKNOWN;
                    break;
                } else {
                    return true;
                }

            case Gdk.BUTTON_SECONDARY:
                drawing_with_state = CellState.EMPTY;
                break;

            default:
                return false;
        }

        mark_current_cell (drawing_with_state);
        return true;
    }

    private bool on_grid_button_release () {
        drawing_with_state = CellState.UNDEFINED;
        return true;
    }

    private void on_mode_switch_changed (Gtk.Widget widget) {
        game_state = widget.get_data ("mode");
    }

    private void on_size_changer_changed (Dimensions dim) {
        if (dim != dimensions) {
            resize_to (dim);
        }
    }

    public void quit () {
        save_game_state ();
    }
}
}
