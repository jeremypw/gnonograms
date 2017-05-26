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
    private const int MAXTRIES = 5;

    public GLib.Settings settings {get; construct;}
    public GLib.Settings saved_state {get; construct;}

    private View view;
    private Model? model;
    private Solver solver;

    private Gee.Deque<Move> back_stack;
    private Gee.Deque<Move> forward_stack;

    public GameState game_state {
        get {
            return view.game_state;
        }

        set {
            view.game_state = value;
            model.game_state = value;
            clear_history ();
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

    public uint grade {
        get {return view.grade;}
    }

    private Dimensions dimensions {get {return view.dimensions;}}
    private uint rows {get { return view.rows; }}
    private uint cols {get { return view.cols; }}

    public Gtk.Window window {
        get {
            return (Gtk.Window)view;
        }
    }

    public signal void quit_app ();

    construct {
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();

        settings = new Settings ("apps.gnonograms-elementary.settings");
        saved_state = new Settings ("apps.gnonograms-elementary.saved-state");
    }

    public Controller (File? game = null) {
        Object (game: game);

        restore_settings ();
        /* Dummy pending restore settings implementation */

        Dimensions dimensions = {20, 15};

        var grade = 4;
        model = new Model (dimensions);
        view = new View (dimensions, grade, model);
        solver = new Solver (dimensions);

        connect_signals ();

        if (game == null || !load_game (game)) {
            new_game ();
        }
    }

    private void connect_signals () {
        view.resized.connect (on_view_resized);
        view.moved.connect (on_moved);
        view.next_move_request.connect (on_next_move_request);
        view.previous_move_request.connect (on_previous_move_request);
        view.game_state_changed.connect (on_state_changed);
        view.random_game_request.connect (new_random_game);
        view.check_errors_request.connect (on_check_errors_request);
        view.delete_event.connect (on_view_deleted);

        solver.showsolvergrid.connect (on_show_solver_grid);
    }

    private void new_game () {
        model.blank_solution ();
        game_state = GameState.SETTING;
        view.header_title = _("Blank sheet");
    }

    public void new_random_game() {
        int passes = 0, count = 0;
        uint grd = grade; //grd may be reduced but this.grade always matches spin setting
        /* One row used to debug */
        var limit = rows == 1 ? 1 : 100;

        view.header_title = _("Random pattern");
        view.blank_labels ();
        clear_history ();
        game_state = GameState.SETTING;

        while (count < limit) {
            count++;
            passes = generate_simple_game (grd); //tries max tries times

            if (passes > grd || passes < 0) {
                break;
            }

            if (passes == 0 && grd > 1) {
                grd--;
            }

            //no simple game generated with this setting -
            //reduce complexity setting (relationship between complexity setting
            //and ease of solution not simple - depends also on grid size)
        }

        if (passes >= 0 && rows > 1) {
            game_state = GameState.SOLVING;
        } else {
            Utils.show_warning_dialog(_("Error occurred in solver"));
            game_state = GameState.SOLVING;
            for (int r = 0; r < rows; r++) {
                for (int c = 0; c < cols; c++) {
                    model.set_data_from_rc (r, c, solver.grid.get_data_from_rc (r, c));
                }
            }
        }
    }

    private int generate_simple_game (uint grd) {
        /* returns 0 - failed to generate solvable game
         * returns value > 1 - generated game took value passes to solve
         * returns -1 - an error occurred in the solver
        */
        uint tries = 0;
        int passes = 0;

        uint limit = rows == 1 ? 1 : MAXTRIES;

        while (passes == 0 && tries <= limit) {
            tries++;
            passes = generate_game (grd);
        }

        return passes;
    }

    private int generate_game (uint grd) {
        model.fill_random (grd); //fills solution grid
        /* Currently only want simple and unique solutions */
        return solve_game (false, false, false, false, true); // no start grid, dont use labels, no advanced
    }


    private void save_game_state () {
        int x, y;
        window.get_position (out x, out y);
        saved_state.set_int ("window-x", x);
        saved_state.set_int ("window-y", y);
    }

    private void restore_settings () {
    }

    private bool load_game (File game) {
        new_game ();  /* TODO implement saving and restoring settings */
        return true;
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

    private void make_move (Move mv) {
        model.set_data_from_cell (mv.cell);

        view.make_move (mv);
        update_history_view ();
    }

    private void update_history_view () {
        view.can_go_back = back_stack.size > 0;
        view.can_go_forward = forward_stack.size > 0;
    }

    private void clear_history () {
        forward_stack.clear ();
        back_stack.clear ();
        update_history_view ();
    }

    /*** Solver related functions ***/

    private int solve_game (bool use_startgrid,
                            bool use_labels,
                            bool use_advanced,
                            bool use_ultimate,
                            bool unique_only) {

        int passes = -1; //indicates error - TODO use throw error

        if (prepare_to_solve (use_startgrid, use_labels)) {
            passes = solver.solve_it (rows == 1, use_advanced, use_ultimate, unique_only);
        }

        return passes;
    }

    private bool prepare_to_solve (bool use_startgrid, bool use_labels) {
        My2DCellArray? startgrid = null;

        if (use_startgrid) {
            startgrid = new My2DCellArray (dimensions, CellState.UNKNOWN);

            for (int r = 0; r < rows; r++) {
                for (int c = 0; c < cols; c++) {
                    startgrid.set_data_from_rc (r, c, model.get_data_from_rc (r, c));
                }
            }
        }

        bool res;
        if (use_labels) {
            res = solver.initialize (view.get_row_clues (), view.get_col_clues (), startgrid, null);
        } else {
            var row_clues = new string [rows];
            var col_clues = new string [cols];

            for (int i = 0; i < rows; i++) {
                row_clues[i] = model.get_label_text (i, false);
            }

            for (int i = 0; i < cols; i++) {
                col_clues[i] = model.get_label_text (i, true);
            }

            res = solver.initialize (row_clues, col_clues, startgrid, null);
        }

        return res;
    }

    public void quit () {
        save_game_state ();
        quit_app ();
    }

/*** Signal Handlers ***/
    private uint on_check_errors_request () {
        return model.count_errors ();
    }

    private void on_show_solver_grid () {

    }

    private void on_moved (Cell cell) {
        var prev_state = model.get_data_for_cell (cell);
        model.set_data_from_cell (cell);

        if (prev_state != cell.state) {
            record_move (cell, prev_state);
        }
    }

    private bool on_next_move_request () {
        if (forward_stack.size > 0) {
            Move mv = forward_stack.poll_head ();
            back_stack.offer_head (mv);

            make_move (mv);

            return true;
        } else {
            return false;
        }
    }

    private bool on_previous_move_request () {
        if (back_stack.size > 0) {
            Move mv = back_stack.poll_head ();
            /* Record copy otherwise it will be altered by next line*/
            forward_stack.offer_head (mv.clone ());

            mv.cell.state = mv.previous_state;
            make_move (mv);

            return true;
        } else {
            return false;
        }
    }

    private void on_view_resized () {
        model.dimensions = dimensions;
        solver.dimensions = dimensions;

        model.clear ();
        game_state = GameState.SETTING;
    }

    private void on_state_changed (GameState gs) {
        game_state = gs;
    }

    private bool on_view_deleted () {
        quit ();
        return false;
    }
}
}
