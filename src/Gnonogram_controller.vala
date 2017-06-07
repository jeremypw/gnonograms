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

    public View view {get; private set;}
    private Model? model;
    private Solver solver;
    private string? game_path = null;
    public string load_game_dir {get; set;}
    public string save_game_dir {get; set;}
    public string current_game_path {get; construct;}

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

    public bool is_solving {
        get {return game_state == GameState.SOLVING;}
    }

    public Difficulty grade {
        get {return view.grade;}
        set {view.grade = value;}
    }

    private Dimensions dimensions {get {return view.dimensions;}}
    public uint rows {get {return view.rows;}}
    public uint cols {get {return view.cols;}}

    public Gtk.Window window {
        get {
            return (Gtk.Window)view;
        }
    }

    public string title {
        get {return view.header_title;}
        set {view.header_title = value;}
    }

    public signal void quit_app ();

    public Controller (File? game = null) {
        bool success = false;

        if (game != null) {
            success = load_game (game, true);
        } else {
            success = restore_game ();
        }

        if (!success) {
            if (is_solving && title == null) {
                new_random_game ();
            } else {
                new_game ();
            }
        }

        view.show_all ();
    }

    construct {
        model = new Model ();
        view = new View (model);
        solver = new Solver ();
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();

        connect_signals ();

        settings = new Settings ("apps.gnonograms-elementary.settings");
        saved_state = new Settings ("apps.gnonograms-elementary.saved-state");
        saved_state.bind ("font-height", view, "fontheight", SettingsBindFlags.DEFAULT);
        saved_state.bind ("mode", view, "game_state", SettingsBindFlags.DEFAULT);
        settings.bind ("grade", view, "grade", SettingsBindFlags.DEFAULT);

        load_game_dir = get_app ().build_pkg_data_dir + "/games";
        save_game_dir = Environment.get_home_dir () + "/gnonograms";
        string data_home_folder_current = Path.build_path (Path.DIR_SEPARATOR_S,
                                                Environment.get_user_data_dir (),
                                                "gnonograms",
                                                "unsaved"
                                            );

        restore_settings ();
        restore_saved_state ();

        /* Ensure these directories exist */
        File file;
        try {
            file = File.new_for_path (save_game_dir);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {warning ("Could not make %s - %s",file.get_uri (), e.message);}
        try {
            file = File.new_for_path (load_game_dir);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {warning ("Could not make %s - %s",file.get_uri (), e.message);}
        try {
            file = File.new_for_path (data_home_folder_current);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {warning ("Could not make %s - %s",file.get_uri (), e.message);}

        current_game_path = Path.build_path (Path.DIR_SEPARATOR_S, data_home_folder_current, Gnonograms.UNSAVED_FILENAME);
    }


    private void connect_signals () {
        view.resized.connect (on_view_resized);
        view.moved.connect (on_moved);
        view.next_move_request.connect (on_next_move_request);
        view.previous_move_request.connect (on_previous_move_request);
        view.game_state_changed.connect (on_state_changed);
        view.random_game_request.connect (new_random_game);
        view.check_errors_request.connect (on_check_errors_request);
        view.rewind_request.connect (on_rewind_request);
        view.delete_event.connect (on_view_deleted);
        view.save_game_request.connect (on_save_game_request);
        view.save_game_as_request.connect (on_save_game_as_request);
        view.open_game_request.connect (on_open_game_request);

        solver.showsolvergrid.connect (on_show_solver_grid);
    }

    private void clear () {
        view.blank_labels ();
        model.clear ();
        clear_history ();
        game_path = "";

        game_state = GameState.SETTING;
    }

    private void new_game () {
        clear ();
        title = _("Blank sheet");
    }

    public void new_random_game() {
        int passes = 0, count = 0;
        uint grd = grade; //grd may be reduced but this.grade always matches spin setting
        /* One row used to debug */
        var limit = rows == 1 ? 1 : 100;

        clear ();
        view.header_title = _("Random pattern");

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

        save_current_game ();
    }

    private void save_current_game () {
        try {
            var current_game = File.new_for_path (current_game_path);
            current_game.@delete ();
        } catch (GLib.Error e) {
            warning ("Error deleting current game file - %s", e.message);
        } finally {
            write_game (current_game_path);
        }
    }

    private void restore_saved_state () {
        int x, y;
        x = saved_state.get_int ("window-x");
        y = saved_state.get_int ("window-y");

        window.move (x, y);
    }

    private void restore_settings () {
        var rows = settings.get_uint ("rows");
        var cols = settings.get_uint ("columns");
        view.dimensions = {cols, rows};

        var dir = settings.get_string ("load-game-dir");
        if (dir.length > 0) {
            load_game_dir = dir;
        }

        dir = settings.get_string ("save-game-dir");
        if (dir.length > 0) {
            save_game_dir = dir;
        }
    }

    private bool restore_game () {
        var current_game = File.new_for_path (current_game_path);
        return load_game (current_game, false);
    }

    private bool write_game (string? path) {
        Filewriter file_writer;

        try {
            file_writer = new Filewriter (window,
                                          save_game_dir,
                                          path,
                                          title,
                                          rows,
                                          cols,
                                          view.get_row_clues (),
                                          view.get_col_clues ()
                            );

            file_writer.difficulty = grade;
            file_writer.game_state = game_state;
            file_writer.working = model.working_data;
            file_writer.solution = model.solution_data;
            file_writer.write_position_file ();
            game_path = file_writer.game_path;
        } catch (IOError e) {
            debug ("File writer error %s", e.message);
            return false;
        }

        return true;
    }

    private bool load_game (File? game, bool update_load_dir) {
        Filereader? reader = null;

        try {
            reader = new Filereader (window, load_game_dir, game);
        } catch (GLib.IOError e) {
            if (!(e is IOError.CANCELLED)) {
                if (reader != null) {
                    Utils.show_warning_dialog (reader.err_msg);
                } else {
                    debug ("Failed to create game file reader - %s", e.message);
                }
            }

            return false;
        }

        if (reader.valid && load_common (reader) && load_position_extra (reader)) {
            if (reader.state != GameState.UNDEFINED) {
                game_state = reader.state;
            } else {
                game_state = GameState.SOLVING;
            }

            if (update_load_dir) {
                /* At this point, we can assume game_file exists and has parent */
                load_game_dir = reader.game_file.get_parent ().get_uri ();
                game_path = reader.game_file.get_path ();
            }
        } else {
            /* There is something wrong with the file being loaded */
            Utils.show_warning_dialog (reader.err_msg, view);
            return false;
        }

        return true;
    }

    private bool load_common (Filereader reader) {
        if (reader.has_dimensions) {
            if (reader.rows > MAXSIZE || reader.cols > MAXSIZE) {
                reader.err_msg = (_("Dimensions too large"));
                return false;
            } else if (reader.rows < MINSIZE || reader.cols < MINSIZE) {
                reader.err_msg = (_("Dimensions too small"));
                return false;
            } else {
                view.dimensions = {reader.cols, reader.rows};
            }
        } else {
            reader.err_msg = (_("Dimensions data missing"));
            return false;
        }

        if (reader.has_solution) {
            model.game_state = GameState.SETTING; /* Selects the solution grid */

            for (int i = 0; i < rows; i++) {
                model.set_row_data_from_string (i, reader.solution[i]);
            }
        } else if (reader.has_row_clues && reader.has_col_clues) {
            view.update_labels_from_string_array (reader.row_clues, false);
            view.update_labels_from_string_array (reader.col_clues, true);

            int passes = solve_game (false, true, true, false, false);

            if (passes > 0 && passes < 999999) {
                set_model_from_solver ();
            } else if (passes < 0) {
                reader.err_msg = (_("Clues contradictory"));
                return false;
            } else {
                Utils.show_warning_dialog (_("Puzzle not solved by computer - may not be possible"), view);
            }
        } else {
            reader.err_msg = (_("Clues and solution both missing"));
            return false;
        }

        if (reader.name.length > 1) {
            title = reader.name;
        } else if (reader.game_file != null) {
            title = reader.game_file.get_basename ();
        }

#if 0 //To be implemented (maybe)
        view.set_source(reader.author);
        view.set_date(reader.date);
        view.set_license(reader.license);
        view.set_score(reader.score);
#endif

        return true;
    }

    private bool load_position_extra (Filereader reader) {
        if (reader.has_working) {
            model.game_state = GameState.SOLVING; /* Selects the working grid */

            for (int i = 0; i < rows; i++) {
                model.set_row_data_from_string (i, reader.working[i]);
            }
        }

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
        }

        back_stack.offer_head (new_move);
        update_history_view ();

        /* Check if puzzle finished */
        if (is_solving && back_stack.size == rows * cols) {
            var errors = model.count_errors ();
            if (errors == 0) {
                view.send_notification (_("Congratulations. You have solved the puzzle"));
                game_state = GameState.SETTING;
            } else {
                view.send_notification (_("You have made some errors"));
                rewind_until_correct ();
            }
        }
    }

    private void set_model_from_solver () {
        foreach (Cell c in solver.solution) {
            model.set_data_from_cell (c);
        }
    }

    private void rewind_until_correct () {
        while (on_previous_move_request () && model.count_errors () > 0) {
            continue;
        }
    }

    private void make_move (Move mv) {
        model.set_data_from_cell (mv.cell);

        view.make_move (mv);
        update_history_view ();
    }

    private void update_history_view () {
        view.can_go_back = back_stack.size > 0;
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

    private void on_rewind_request () {
        rewind_until_correct ();
    }

    private void on_view_resized () {
        model.dimensions = dimensions;
        solver.dimensions = dimensions;

        model.clear ();
        game_state = GameState.SETTING;

        settings.set_uint ("rows", rows);
        settings.set_uint ("columns", cols);
    }

    private void on_state_changed (GameState gs) {
        game_state = gs;
    }

    private bool on_view_deleted () {
        quit ();
        return false;
    }

    private void on_save_game_request () {
        write_game (game_path);
    }

    private void on_save_game_as_request () {
        write_game (null); /* Will cause Filewriter to ask for a location to save */
    }

    private void on_open_game_request () {
        load_game (null, true); /* Will cause Filereader to ask for a location to open */
    }
}
}
