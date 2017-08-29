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
/*** Controller class is created by the Application class. It coordinates all other classes and
   * provides business logic. Most of its properties and functions are private.
***/
public class Controller : GLib.Object {
/** PUBLIC SIGNALS, PROPERTIES, FUNCTIONS AND CONSTRUCTOR **/
    public signal void quit_app ();

    public Gtk.Window window {
        get {
            return (Gtk.Window)view;
        }
    }

    public string load_game_dir { get; private set; }

    public Controller (File? game = null) {
        if (game != null) {
            load_game.begin (game, true, (obj, res) => {
                if (!load_game.end (res)) {
                    new_or_random_game ();
                }
            });
        } else {
            restore_game.begin ((obj, res) => {
                if (!restore_game.end (res)) {
                    new_or_random_game ();
                }
            });
        }

        view.show_all ();
    }

    private void new_or_random_game () {
        if (is_solving && title == null) {
            new_random_game.begin ();
        } else {
            new_game ();
        }
    }

    public void quit () {
        save_game_state ();
        save_settings ();
        quit_app ();
    }

/** PRIVATE **/
    private View view;
    private Model model;
    private Solver solver;
    private GLib.Settings settings;
    private GLib.Settings saved_state;
    private Gee.Deque<Move> back_stack;
    private Gee.Deque<Move> forward_stack;
    private const int MAX_TRIES = 1000;
    private string save_game_dir;
    private string current_game_path;
    private string? game_path = null;

    private GameState game_state {
        get {
            return view.game_state;
        }

        set {
            view.game_state = value;
            model.game_state = value;
            clear_history ();
        }
    }

    private Difficulty grade {
        get {
            return view.grade;
        }

        set {
            view.grade = value;
        }
    }


    private Dimensions dimensions {
        get {
            return view.dimensions;
        }
    }

    private bool is_solving {
        get {
            return game_state == GameState.SOLVING;
        }
    }

    private uint rows {
        get {
            return view.rows;
        }
    }

    private uint cols {
        get {
            return view.cols;
        }
    }

    private string title {
        get {
            return view.header_title;
        }

        set {
            view.header_title = value;
        }
    }

    construct {
        model = new Model ();
        view = new View (model);
        solver = new Solver ();
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();
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

        /* Connect signals. Must be done before restoring settings so that e.g.
         * dimensions of model are set. */
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
        view.solve_this_request.connect (on_solve_this_request);
        view.restart_request.connect (on_restart_request);

        restore_settings (); /* May change load_game_dir and save_game_dir */
        restore_saved_state ();

        /* Ensure load save and data directories exist */
        File file;
        try {
            file = File.new_for_path (save_game_dir);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Could not make %s - %s",file.get_uri (), e.message);
            }
        }

        try {
            file = File.new_for_path (load_game_dir);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Could not make %s - %s",file.get_uri (), e.message);
            }
        }

        try {
            file = File.new_for_path (data_home_folder_current);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Could not make %s - %s",file.get_uri (), e.message);
            }
        }

        current_game_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                             data_home_folder_current,
                                             Gnonograms.UNSAVED_FILENAME);
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

    private async void new_random_game() {
        uint passes = 0;
        uint count = 0;
        uint grd = grade; //grd may be reduced but this.grade always matches spin setting
        /* One row used to debug */
        var limit = rows == 1 ? 1 : 100;

        clear ();
        view.header_title = _("Random pattern");
        view.show_generating ();

        int target = Utils.grade_to_passes (grd);
        int next_target = Utils.grade_to_passes (grd + 1);

        while (count < limit) {
            count++;
            passes = yield try_generate_game (grd); //tries max tries times


            if (passes >= target) {
                if (passes < next_target) {
                    break;
                } else {
                    continue;
                }
            }

            if (passes > 0 && grd < Difficulty.CHALLENGING) {
                grd++;
            }
        }

        if (count >= limit) {
            view.send_notification (_("Failed to generate game of required grade"));
        } else if (passes >= 0 && rows > 1) {
            view.update_labels_from_model ();
            game_state = GameState.SOLVING;
            view.send_notification (_("Difficulty: %s").printf (Utils.passes_to_grade_description (passes)));
        } else {
            view.send_notification (_("Error occurred in solver"));
            game_state = GameState.SOLVING;
            for (int r = 0; r < rows; r++) {
                for (int c = 0; c < cols; c++) {
                    model.set_data_from_rc (r, c, solver.grid.get_data_from_rc (r, c));
                }
            }
        }

        view.hide_progress ();
    }

    private async uint try_generate_game (uint grd) {
        /* returns 0 - failed to generate solvable game
         * returns value > 1 - generated game took value passes to solve
         * returns uint.MAX - an error occurred in the solver
        */
        uint tries = 0;
        uint passes = 0;

        uint limit = rows == 1 ? 1 : MAX_TRIES;

        while (passes == 0 && tries <= limit) {
            tries++;
            passes = yield generate_game (grd);
        }

        return passes;
    }

    /** Generate a random, soluble puzzle (simple and unique solution only) **/
    private async uint generate_game (uint grd) {
        model.fill_random (grd);

        return yield solve_game (false, // no start_grid
                                 false, // use model
                                 grd >= Difficulty.ADVANCED,
                                 false, // no ultimate solutions
                                 grd < Difficulty.MAXIMUM); // unique solutions only
    }


    private void save_game_state () {
        int x, y;
        window.get_position (out x, out y);
        saved_state.set_int ("window-x", x);
        saved_state.set_int ("window-y", y);
        saved_state.set_string ("current-game-path", game_path);

        save_current_game ();
    }

    private void save_settings () {
        settings.set_string ("save-game-dir", save_game_dir);
        settings.set_string ("load-game-dir", load_game_dir);
    }

    private void save_current_game () {
        try {
            var current_game = File.new_for_path (current_game_path);
            current_game.@delete ();
        } catch (GLib.Error e) {
            warning ("Error deleting current game file - %s", e.message);
        } finally {
            write_game (current_game_path, true);
        }
    }

    private void restore_saved_state () {
        int x, y;
        x = saved_state.get_int ("window-x");
        y = saved_state.get_int ("window-y");
        game_path = saved_state.get_string ("current-game-path");

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

    private async bool restore_game () {
        var current_game = File.new_for_path (current_game_path);
        return yield load_game (current_game, false);
    }

    private string? write_game (string? path, bool save_state = false) {
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
            if (save_state) {
                file_writer.write_position_file ();
            } else {
                file_writer.write_game_file ();
            }
        } catch (IOError e) {
            critical ("File writer error %s", e.message);
            return null;
        }

        return file_writer.game_path;
    }

    private async bool load_game (File? game, bool update_load_dir) {
        Filereader? reader = null;
        clear ();

        try {
            reader = new Filereader (window, load_game_dir, game);
        } catch (GLib.IOError e) {
            if (!(e is IOError.CANCELLED)) {
                if (reader != null) {
                    view.send_notification (reader.err_msg);
                } else {
                    critical ("Failed to create game file reader - %s", e.message);
                }
            }

            return false;
        }

        if (reader.valid && (yield load_common (reader)) && load_position_extra (reader)) {
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
            view.send_notification (reader.err_msg);
            return false;
        }

        return true;
    }

    private async bool load_common (Filereader reader) {
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
            reader.err_msg = (_("Dimensions missing"));
            return false;
        }

        if (reader.has_row_clues && reader.has_col_clues) {
            view.update_labels_from_string_array (reader.row_clues, false);
            view.update_labels_from_string_array (reader.col_clues, true);
        } else {
            reader.err_msg = (_("Clues missing"));
            return false;
        }

        model.game_state = GameState.SETTING; /* Selects the solution grid */

        if (reader.has_solution) {
            for (int i = 0; i < rows; i++) {
                model.set_row_data_from_string (i, reader.solution[i]);
            }
        } else {
            uint passes = yield solve_game (false, // no startgrid
                                            true, // use loaded labels, not model
                                            true, // use advanced solver
                                            false, // do not use ultimate solver (to time consuming for loading)
                                            false); // do not insist unique solution exists

            if (passes > 0 && passes < Gnonograms.FAILED_PASSES) {
                set_model_from_solver ();
                view.update_labels_from_model ();
            } else if (passes < 0) {
                reader.err_msg = (_("Clues contradictory"));
                return false;
            } else {
                view.send_notification (_("Puzzle not solved by computer - may not be possible"));
            }
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

    private void record_move (Cell cell, CellState previous_state) {
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
        if (is_solving && model.is_finished ()) {
            if (model.count_errors () == 0) {
                view.send_notification (_("Correct solution"));
                game_state = GameState.SETTING;
            } else {
                view.send_notification (_("There are errors"));
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
    /********************************/

    /** Solve a puzzle
      * @use_startgrid: continue solving partially filled grid.
      * @use_labels: use text clues from view labels rather than from model (used
      * for solving manually entered games (if implemented).
      * @use_advanced: If simple solver fails, continue with advanced solver.
      * @use_ultimate: I advanced solver fails continue with ultimate solver (time consuming).
      * @unique_only: Only accept unique solutions (otherwise puzzle regarded insoluble).
    **/
    private async uint solve_game (bool use_startgrid,
                                   bool use_labels,
                                   bool use_advanced,
                                   bool use_ultimate,
                                   bool unique_only,
                                   bool human = false) {

        uint passes = uint.MAX; //indicates error - TODO use throw error

        if (prepare_to_solve (use_startgrid, use_labels)) {
            /* Single row puzzles used for development and debugging */
            passes = yield solver.solve_it (rows == 1, use_advanced, use_ultimate, unique_only, human);
        } else {
            critical ("could not prepare solver");
        }


        return passes;
    }

    /** Initialize solver **/
    private bool prepare_to_solve (bool use_startgrid, bool use_labels = false) {
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

/*** Signal Handlers ***/

    private uint on_check_errors_request () {
        return model.count_errors ();
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

        view.queue_draw ();
    }

    private void on_state_changed (GameState gs) {
        game_state = gs;
    }

    private bool on_view_deleted () {
        quit ();
        return false;
    }

    private void on_save_game_request () {
        var write_path = write_game (game_path, false); /* Do not save working */

        if (game_path == null || game_path == "") {
            game_path = write_path;
        }
    }

    private void on_save_game_as_request () {
        var write_path = write_game (null, false); /* Will cause Filewriter to ask for a location to save */

        if (write_path != null) {
            game_path = write_path;
        }
    }

    private void on_open_game_request () {
        load_game.begin (null, true); /* Will cause Filereader to ask for a location to open */
    }

    private void on_solve_this_request () {
        string msg = "";
        model.blank_working ();
        game_state = GameState.SOLVING;

        view.show_solving ();

        /* Look for unique simple solution */
        solve_game.begin (false, // no startgrid
                          true, // use labels not model
                          false, // no advanced solutions
                          false, // no ultimate solutions
                          true, // must be unique solution
                          false, // not human
                          (obj, res) => {
            uint passes = solve_game.end (res);

            if (passes > 0  && passes < Gnonograms.FAILED_PASSES) {
                msg =  _("Simple solution found in %u passes.  Graded as %s").printf (passes, Utils.passes_to_grade_description (passes));
                after_solve_game (msg);
            } else if (passes == 0 || passes == Gnonograms.FAILED_PASSES) {
                msg = _("No simple solution found");
                solve_game.begin (false, // no startgrid
                                  true, // use labels not model
                                  true, // use advanced solver
                                  true, // use ultimate if necessary (option cancel given)
                                  false, // do not insist on unique
                                  false, // not human
                                  (obj, res) => {

                    passes = solve_game.end (res);

                    if (passes > 0 && passes < Gnonograms.FAILED_PASSES) {
                        msg = msg + "\n" + _("Advanced solution found in %u passes.  Graded as %s").printf (passes, Utils.passes_to_grade_description (passes));
                    } else if (passes == 0 || passes == Gnonograms.FAILED_PASSES) {
                        msg = msg + "\n" + _("No advanced solution found");
                    }

                    after_solve_game (msg);
                    view.queue_draw ();
                });
            }

            after_solve_game (msg);
            view.queue_draw ();
        });
    }

    private void after_solve_game (string msg) {
        view.send_notification (msg);

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                model.set_data_from_rc (r, c, solver.grid.get_data_from_rc (r, c));
            }
        }

        view.hide_progress ();
    }

    private void on_restart_request () {
        if (game_state == GameState.SETTING) {
            new_game ();
        } else {
            model.blank_working ();
            clear_history ();
            view.queue_draw ();
        }
    }
}
}
