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
    private View view;
    private Model? model;
    private Gee.Deque<Move> back_stack;
    private Gee.Deque<Move> forward_stack;

    public GameState game_state {
        get {
            return view.game_state;
        }

        set {
            view.game_state = value;
            model.game_state = value;
        }
    }

    private File? _game;
    public File? game {
        get {
            return _game;
        }

        set {
            _game = value;

            if (value != null) {
                view.header_title = value.get_uri ();
            }
        }
    }

    public uint grade {get; set;}

    private uint rows {get { return view.rows; }}
    private uint cols {get { return view.rows; }}

    public Gtk.Window window {
        get {
            return (Gtk.Window)view;
        }
    }

    construct {
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();
    }

    public Controller (File? game = null) {
        Object (game: game);

        restore_settings ();
        /* Dummy pending restore settings implementation */
        grade = 4;
        Dimensions dimensions = {15, 25};

        model = new Model (dimensions);
        view = new View (dimensions, grade, model);
        connect_signals ();

        if (game == null || !load_game (game)) {
            new_game ();
        }
    }

    private void connect_signals () {
        view.resized.connect (on_resized);
        view.moved.connect (on_moved);
        view.next_move_request.connect (get_next_move);
        view.previous_move_request.connect (get_previous_move);
        view.game_state_changed.connect (on_state_changed);
    }

    private void new_game () {
        model.blank_solution ();
        view.game_state = GameState.SETTING;
        view.header_title = _("Blank sheet");
    }

    private void new_random_game () {
        /* TODO  Check/confirm overwriting existing game */
        model.fill_random (grade);
        view.game_state = GameState.SOLVING;
        view.header_title = _("Random game");
    }

    private void save_game_state () {
    }

    private void restore_settings () {
    }

    private bool load_game (File game) {
        new_game ();  /* TODO implement saving and restoring settings */
        return true;
    }

//~     private void handle_arrow_keys (string keyname, uint mods) {
//~         int r = 0; int c = 0;
//~         switch (keyname) {
//~             case "UP":
//~                     r = -1;
//~                     break;
//~             case "DOWN":
//~                     r = 1;
//~                     break;
//~             case "LEFT":
//~                     c = -1;
//~                     break;
//~             case "RIGHT":
//~                     c = 1;
//~                     break;

//~             default:
//~                     return;
//~         }

//~         cell_grid.move_cursor_relative (r, c);
//~     }

//~     private void handle_pen_keys (string keyname, uint mods) {
//~         if (mods > 0) {
//~             return;
//~         }

//~         switch (keyname) {
//~             case "F":
//~                 drawing_with_state = CellState.FILLED;
//~                 break;

//~             case "E":
//~                 drawing_with_state = CellState.EMPTY;
//~                 break;

//~             case "X":
//~                 if (game_state == GameState.SOLVING) {
//~                     drawing_with_state = CellState.UNKNOWN;
//~                     break;
//~                 } else {
//~                     return;
//~                 }

//~             default:
//~                     return;
//~         }

//~         make_move_at_current_cell (drawing_with_state);
//~     }

    private void on_moved (Cell cell) {
        var prev_state = model.get_data_for_cell (cell);
        model.set_data_from_cell (cell);

        if (prev_state != cell.state) {
            record_move (cell, prev_state);
        }
    }

    public void record_move (Cell cell, CellState previous_state) {
        var new_move = new Move (cell, previous_state);

        if (new_move.cell.state != CellState.UNDEFINED) {
            Move? current_move = back_stack.peek_head ();
            if (current_move != null && current_move.equal (new_move)) {
                return;
            }

            forward_stack.clear ();
        }

        back_stack.offer_head (new_move);
    }

    private Move? get_next_move () {
        if (forward_stack.size > 0) {
            Move mv = forward_stack.poll_head ();
            back_stack.offer_head (mv);
            return mv;
        } else {
            return null;
        }
    }

    private Move? get_previous_move () {
        if (back_stack.size > 0) {
            Move mv = back_stack.poll_head ();
            forward_stack.offer_head (mv);
            return mv;
        } else {
            return null;
        }
    }

    private void on_resized (Dimensions dim) {
        model.dimensions = dim;
        model.clear ();
    }

    private void on_state_changed (GameState gs) {
        game_state = gs;
    }


/*** Signal Handlers ***/
//~     private bool on_view_key_press_event (Gdk.EventKey event) {
//~         if (event.is_modifier == 1) {
//~             return true;
//~         }

//~         var name = (Gdk.keyval_name (event.keyval)).up();
//~         var mods = (event.state & Gtk.accelerator_get_default_mod_mask ());
//~         bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
//~         bool other_mod_pressed = (((mods & ~Gdk.ModifierType.SHIFT_MASK) & ~Gdk.ModifierType.CONTROL_MASK) != 0);
//~         bool only_control_pressed = control_pressed && !other_mod_pressed; /* Shift can be pressed */
//~         switch (name) {
//~             case "UP":
//~             case "DOWN":
//~             case "LEFT":
//~             case "RIGHT":
//~                 handle_arrow_keys (name, mods);
//~                 break;

//~             case "F":
//~             case "E":
//~             case "X":
//~                 handle_pen_keys (name, mods);
//~                 break;

//~             case "1":
//~             case "2":
//~                 if (only_control_pressed) {
//~                     game_state = name == "1" ? GameState.SETTING : GameState.SOLVING;
//~                 }

//~                 break;

//~             case "MINUS":
//~             case "EQUAL":
//~             case "PLUS":
//~                 if (only_control_pressed) {
//~                     if (name == "MINUS") {
//~                         fontheight -= 1.0;
//~                     } else {
//~                         fontheight += 1.0;
//~                     }
//~                 }

//~                 break;

//~             case "R":
//~                 if (only_control_pressed) {
//~                     new_random_game ();
//~                 }

//~                 break;

//~             default:
//~                 return false;
//~         }
//~         return true;
//~     }

//~     private bool on_view_key_release_event (Gdk.EventKey event) {
//~         var name = (Gdk.keyval_name (event.keyval)).up();

//~         switch (name) {
//~             case "F":
//~             case "E":
//~             case "X":
//~                 drawing_with_state = CellState.UNDEFINED;
//~                 break;

//~             default:
//~                 return false;
//~         }

//~         return true;
//~     }


//~     private void on_mode_switch_changed (Gtk.Widget widget) {
//~         game_state = widget.get_data ("mode");
//~     }

    public void quit () {
        save_game_state ();
    }
}
}
