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
        view.next_move_request.connect (on_next_move_request);
        view.previous_move_request.connect (on_previous_move_request);
        view.game_state_changed.connect (on_state_changed);
        view.random_game_request.connect (new_random_game);
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
            view.can_go_forward = false;
        }

        back_stack.offer_head (new_move);
        update_history_view ();
    }

    private void on_next_move_request () {
        if (forward_stack.size > 0) {
            Move mv = forward_stack.poll_head ();
            back_stack.offer_head (mv);

            make_move (mv);
        }
    }

    private void on_previous_move_request () {
        if (back_stack.size > 0) {
            Move mv = back_stack.poll_head ();
            /* Record copy otherwise it will be altered by next line*/
            forward_stack.offer_head (mv.clone ());

            mv.cell.state = mv.previous_state;
            make_move (mv);
        }
    }

    private void make_move (Move mv) {
        model.set_data_from_cell (mv.cell);

        view.make_move (mv);
        update_history_view ();
    }

    private void update_history_view () {
        view.can_go_back = back_stack.size > 0;
        view.can_go_forward = forward_stack.size > 0;
    }

    private void on_resized (Dimensions dim) {
        model.dimensions = dim;
        model.clear ();
    }

    private void on_state_changed (GameState gs) {
        game_state = gs;
    }


/*** Signal Handlers ***/
    public void quit () {
        save_game_state ();
    }
}
}
