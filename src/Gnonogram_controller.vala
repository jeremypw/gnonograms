/* Controller class for gnonograms - creates model and view, handles user input and settings.
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
 *  Jeremy Wootten <jeremywootten@gmail.com>
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
        if (is_solving && game_name == null) {
            on_new_random_request ();
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
    private GLib.Settings? settings;
    private GLib.Settings? saved_state;
    private Gee.Deque<Move> back_stack;
    private Gee.Deque<Move> forward_stack;
    private string save_game_dir;
    private string load_game_dir;
    private string current_game_path;
    private string temporary_game_path;
    private bool is_readonly {
        get {
            return view.readonly;
        }
        set {
            view.readonly = value;
        }
    }

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

    private Difficulty generator_grade {
        get {
            return view.generator_grade;
        }

        set {
            view.generator_grade = value;
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

    private string game_name {
        get {
            return view.game_name;
        }

        set {
            view.game_name = value;
        }
    }

    construct {
        model = new Model ();
        view = new View (model);
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();

        var schema_source = GLib.SettingsSchemaSource.get_default ();
        if (schema_source.lookup ("com.github.jeremypw.gnonograms.settings", true) != null &&
            schema_source.lookup ("com.github.jeremypw.gnonograms.saved-state", true) != null) {

            settings = new Settings ("com.github.jeremypw.gnonograms.settings");
            saved_state = new Settings ("com.github.jeremypw.gnonograms.saved-state");
        }

        save_game_dir = Environment.get_home_dir () + "/gnonograms";
        load_game_dir = save_game_dir;

        string data_home_folder_current = Path.build_path (
                                                Path.DIR_SEPARATOR_S,
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
        view.random_game_request.connect (on_new_random_request);
        view.check_errors_request.connect (on_count_errors_request);
        view.rewind_request.connect (on_rewind_request);
        view.delete_event.connect (on_view_deleted);
        view.save_game_request.connect (on_save_game_request);
        view.save_game_as_request.connect (on_save_game_as_request);
        view.open_game_request.connect (on_open_game_request);
        view.solve_this_request.connect (on_solve_this_request);
        view.restart_request.connect (on_restart_request);

        File file;
        try {
            file = File.new_for_path (data_home_folder_current);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Could not make %s - %s",file.get_uri (), e.message);
            }
        }

        current_game_path = null;

        temporary_game_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                             data_home_folder_current,
                                             Gnonograms.UNSAVED_FILENAME);

        restore_settings (); /* May change load_game_dir and save_game_dir */

        /* Ensure load save and data directories exist */

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
    }

    private void clear () {
        model.clear ();
        view.update_labels_from_solution ();
        clear_history ();

        game_state = GameState.SETTING;
        is_readonly = true; // Force Save As when saving new design
    }

    private void new_game () {
        clear ();
        game_name = Gnonograms.UNTITLED_NAME;
    }

    private void on_new_random_request () {
        clear ();

        AbstractGameGenerator gen;
        var cancellable = new Cancellable ();
        gen = new SimpleRandomGameGenerator (dimensions, cancellable);
        gen.grade = generator_grade;

        game_name = _("Random pattern");
        view.game_grade = Difficulty.UNDEFINED;
        view.show_working (cancellable, "Generating");
        start_generating (cancellable, gen);
    }

    private void start_generating (Cancellable cancellable, AbstractGameGenerator gen) {
        new Thread<void*> (null, () => {
            var success = gen.generate ();
            /* Gtk is not thread-safe so must invoke in the main loop */
            MainContext.@default ().invoke (() => {
            /* Show last generated game regardless */
                model.set_solution_from_array (gen.get_solution ());
                view.update_labels_from_solution ();

                if (cancellable.is_cancelled ()) {
                   view.send_notification (_("Game generation was cancelled"));
                } else {
                    if (success) {
                        view.game_grade = gen.solution_grade;
                        game_state = GameState.SOLVING;
                    } else {
                        view.send_notification (_("Failed to generate game of required grade"));
                        game_state = GameState.SETTING;
                    }
                }

                view.hide_progress ();
                view.queue_draw ();

                return false;
            });

            return null;
        });
    }

    private void save_game_state () {
        if (saved_state == null) {
            return;
        }

        int x, y;
        window.get_position (out x, out y);
        saved_state.set_int ("window-x", x);
        saved_state.set_int ("window-y", y);
        if (current_game_path != null) {
            saved_state.set_string ("current-game-path", current_game_path);
        }

        try {
            var current_game = File.new_for_path (temporary_game_path);
            current_game.@delete ();
        } catch (GLib.Error e) {
            debug ("Error deleting temporary game file - %s", e.message);
        } finally {
            /* Save solution and current state */
            write_game (temporary_game_path, true, true);
        }
    }

    private void save_settings () {
        if (settings == null) {
            return;
        }

        settings.set_string ("save-game-dir", save_game_dir);
        settings.set_string ("load-game-dir", load_game_dir);
    }

    private void restore_settings () {
        if (settings != null) {
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

            int x, y;
            x = saved_state.get_int ("window-x");
            y = saved_state.get_int ("window-y");
            current_game_path = saved_state.get_string ("current-game-path");
            window.move (x, y);
            view.fontheight = saved_state.get_double ("font-height");


            saved_state.bind ("font-height", view, "fontheight", SettingsBindFlags.DEFAULT);
            saved_state.bind ("mode", view, "game_state", SettingsBindFlags.DEFAULT);
            settings.bind ("grade", view, "generator_grade", SettingsBindFlags.DEFAULT);
        }
    }

    private async bool restore_game () {
        var current_game = File.new_for_path (temporary_game_path);
        return yield load_game (current_game, false);
    }

    private string? write_game (string? path, bool save_solution = false, bool save_state = false) {
        var file_writer = new Filewriter (window,
                                          save_game_dir,
                                          path,
                                          game_name,
                                          dimensions,
                                          view.get_row_clues (),
                                          view.get_col_clues ()
                                        );

        try {
            file_writer.difficulty = view.game_grade;
            file_writer.game_state = game_state;
            file_writer.working.copy (model.working_data);
            file_writer.solution.copy (model.solution_data);
            file_writer.save_solution = save_solution;
            file_writer.is_readonly = is_readonly;

            if (save_state) {
                file_writer.write_position_file ();
            } else {
                file_writer.write_game_file ();
            }

        } catch (IOError e) {
            var basename = Path.get_basename (file_writer.game_path);
            Utils.show_error_dialog (_("Unable to save %s").printf (basename), e.message);

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
                var basename = _("game");
                if (reader != null && reader.game_file != null) {
                    basename = reader.game_file.get_basename ();
                }

                Utils.show_error_dialog (_("Unable to load %s").printf (basename), e.message, window);
            }

            return false;
        }

        if (reader.valid && (yield load_common (reader))) {
            if (reader.state != GameState.UNDEFINED) {
                game_state = reader.state;
            } else {
                game_state = GameState.SOLVING;
            }

            if (update_load_dir) {
                /* At this point, we can assume game_file exists and has parent */
                load_game_dir = reader.game_file.get_parent ().get_uri ();
            }
        } else {
            /* There is something wrong with the file being loaded */
            Utils.show_error_dialog (_("Invalid game file"), reader.err_msg, window);
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
        model.blank_working (); // Do not reveal solution on load

        if (reader.has_solution) {
            model.game_state = GameState.SETTING; /* Selects the working grid */
            model.set_row_data_from_string_array (reader.solution[0 : rows]);
        } else {
            yield start_solving (false, true); // Sets difficulty in header bar; copies any solution found to solution grid.
        }

        if (reader.name.length > 1 && reader.name != "") {
            game_name = reader.name;
        }

        if (reader.has_working) {
            model.game_state = GameState.SOLVING; /* Selects the working grid */
            model.set_row_data_from_string_array (reader.working[0 : rows]);
        }

        is_readonly = reader.is_readonly;

        if (reader.original_path != null && reader.original_path != "") {
            current_game_path = reader.original_path;
        } else {
            current_game_path = reader.game_file.get_uri ();
        }

#if 0 //To be implemented (maybe)
        view.set_source(reader.author);
        view.set_date(reader.date);
        view.set_license(reader.license);
        view.set_score(reader.score);
#endif

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
        if (is_solving && model.is_finished) {
            if (model.count_errors () == 0) {
                view.send_notification (_("Correct solution"));
            } else if (view.model_matches_labels) {
                view.send_notification (_("Alternative solution found"));
            } else {
                view.send_notification (_("There are errors"));
            }
        }
    }

    private void rewind_until_correct () {
        while (on_previous_move_request () && model.count_errors () > 0) {
            continue;
        }

        if (model.count_errors () > 0) { // Only happens for completed erroneous solution without history.
            model.blank_working (); // have to restart solving
            clear_history (); // just in case - should not be necessary.
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

    /** Solve clues by computer using all available techniques
    **/
    private Difficulty computer_solve_clues (AbstractSolver solver) {
        string[] row_clues;
        string[] col_clues;
        row_clues = view.get_row_clues ();
        col_clues = view.get_col_clues ();

        solver.configure_from_grade (Difficulty.COMPUTER);

        return solver.solve_clues (row_clues, col_clues);
    }

/*** Signal Handlers ***/

    private uint on_count_errors_request () {
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

        clear ();
        game_state = GameState.SETTING;

        if (view.get_realized ()) { /* No need to save if just constructing */
            save_game_state (); /* Forget previous game settings */
        }

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
        if (is_readonly) {
            on_save_game_as_request ();
        } else {
            var path = write_game (current_game_path, true, false);
            if (path != null && path != "") {
                current_game_path = path;
                notify_saved (path);
            }
        }
    }

    private void on_save_game_as_request () {
        /* Filewriter will request save location, no solution saved as default */
        var path = write_game (null, false, false);

        if (path != null) {
            current_game_path = path;
            notify_saved (path);
        }
    }

    private void notify_saved (string path) {
        view.send_notification (_("Saved to %s").printf (path));
    }

    private void on_open_game_request () {
        load_game.begin (null, true); /* Filereader will request load location */
    }

    private void on_solve_this_request () {
        game_state = GameState.SOLVING;
        start_solving.begin (true);
    }

    private async SolverState start_solving (bool copy_to_working = false, bool copy_to_solution = false) {
        /* Need new thread else blocks spinner */
        /* Try as hard as possible to find solution, regardless of grade setting */
        var state = SolverState.UNDEFINED;
        Difficulty diff = Difficulty.UNDEFINED;
        string msg = "";
        var cancellable = new Cancellable ();
        view.show_working (cancellable, "Solving");

        new Thread<void*> (null, () => {
            AbstractSolver solver = new Solver (dimensions, cancellable);
            diff = computer_solve_clues (solver);

            if (cancellable != null && cancellable.is_cancelled ()) {
                msg = _("Solving was cancelled");
            } else if (solver.state.solved ()) {
                msg =  _("Solution found. %s").printf (diff.to_string ());
            } else{
                msg = _("No solution found");
            }

            MainContext.@default ().invoke (() => {
                if (msg != "") {
                    view.send_notification (msg);
                }

                view.game_grade = diff;

                if (solver.state.solved () && copy_to_solution) {
                    model.solution_data.copy (solver.grid);
                }

                if (copy_to_working) {
                    model.working_data.copy (solver.grid);
                }

                view.hide_progress ();
                view.queue_draw ();
                start_solving.callback (); // Needed to continue after yield;
                return false;
            });

            return null;
        });

        yield;
        return state;
    }

    private void on_restart_request () {
        if (game_state == GameState.SETTING) {
            new_game ();
        } else {
            model.blank_working ();
            clear_history ();
        }

        view.update_labels_from_solution ();
        view.queue_draw ();
    }
}
}
