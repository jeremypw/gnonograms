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
    public GameState game_state {get; set;}
    public Dimensions dimensions {get; set;}
    public Difficulty generator_grade {get; set;}

    construct {
        model = new Model ();
        view = new View (model);
        history = new Gnonograms.History ();

        view.moved.connect (on_moved);
        view.next_move_request.connect (on_next_move_request);
        view.previous_move_request.connect (on_previous_move_request);
        view.rewind_request.connect (rewind_until_correct);
        view.delete_event.connect (on_view_deleted);
        view.save_game_request.connect (on_save_game_request);
        view.save_game_as_request.connect (on_save_game_as_request);
        view.open_game_request.connect (on_open_game_request);
        view.solve_this_request.connect (on_solve_this_request);
        view.restart_request.connect (on_restart_request);

        notify["game-state"].connect (() => {
            if (game_state != GameState.UNDEFINED) { /* Do not clear on save */
                clear_history ();
            }

            if (game_state == GameState.GENERATING) {
                on_new_random_request ();
            }
        });

        notify["dimensions"].connect (() => {
            clear ();
            game_state = GameState.SETTING;
        });

        var schema_source = GLib.SettingsSchemaSource.get_default ();
        if (schema_source.lookup ("com.github.jeremypw.gnonograms.settings", true) != null &&
            schema_source.lookup ("com.github.jeremypw.gnonograms.saved-state", true) != null) {

            settings = new Settings ("com.github.jeremypw.gnonograms.settings");
            saved_state = new Settings ("com.github.jeremypw.gnonograms.saved-state");
        }

        string data_home_folder_current = Path.build_path (Path.DIR_SEPARATOR_S,
                                                           Environment.get_user_data_dir (),
                                                           Gnonograms.APP_NAME,
                                                           "unsaved"
                                                           );
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
        temporary_game_path = Path.build_path (Path.DIR_SEPARATOR_S, data_home_folder_current,
                                               Gnonograms.UNSAVED_FILENAME);

        restore_settings (); /* May change load_game_dir and save_game_dir */

        bind_property ("dimensions", model, "dimensions");
        bind_property ("dimensions", view, "dimensions",  BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        bind_property ("generator-grade", view, "generator-grade", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        bind_property ("game-state", model, "game-state");
        bind_property ("game-state", view, "game-state", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);


        history.bind_property ("can-go-back", view, "can-go-back", BindingFlags.SYNC_CREATE | BindingFlags.DEFAULT);
        history.bind_property ("can-go-forward", view, "can-go-forward", BindingFlags.SYNC_CREATE | BindingFlags.DEFAULT);

        saved_state.bind ("mode", this, "game_state", SettingsBindFlags.DEFAULT);
        /* Delay binding font-height so can be applied after loading game */
        settings.bind ("grade", this, "generator_grade", SettingsBindFlags.DEFAULT);

    }

    public Controller (File? game = null) {
        var fh = saved_state.get_double ("font-height");
        saved_state.bind ("font-height", view, "fontheight", SettingsBindFlags.DEFAULT);

        if (game != null) {
            load_game.begin (game, true, (obj, res) => {
                view.fontheight = fh; /* Ensure restored fontheight applied */
                if (!load_game.end (res)) {
                    critical ("Unable to load specified game");
                    new_or_random_game ();
                }
            });
        } else {
            restore_game.begin ((obj, res) => {
                view.fontheight = fh; /* Ensure restored fontheight applied */
                if (!restore_game.end (res)) {
                    critical ("Unable to restore game");
                    new_game ();
                }
            });
        }

        view.show_all ();
        view.present ();
    }

    private void new_or_random_game () {
        if (is_solving && game_name == null) {
            on_new_random_request ();
        } else {
            new_game ();
        }
    }

    public void quit () {
        if (solver != null) {
            solver.cancel ();
        }

        /* If in middle of generating no defined game to save */
        if (generator == null) {
            save_game_state ();
        } else {
            generator.cancel ();
        }

        save_settings ();
        quit_app ();
    }

/** PRIVATE **/
    private View view;
    private Model model;
    private AbstractSolver? solver;
    private AbstractGameGenerator? generator;
    private GLib.Settings? settings;
    private GLib.Settings? saved_state;
    private Gnonograms.History history;
    private string? save_game_dir = null;
    private string? load_game_dir = null;
    private string current_game_path;
    private string? temporary_game_path = null;
    private bool is_readonly {
        get {
            return view.readonly;
        }
        set {
            view.readonly = value;
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


    private void clear () {
        model.clear ();
        view.update_labels_from_solution ();
        clear_history ();
        is_readonly = true; // Force Save As when saving new design
    }

    private void new_game () {
        clear ();
        game_state = GameState.SETTING;
        game_name = Gnonograms.UNTITLED_NAME;
    }

    private void on_new_random_request () {
        clear ();

        var cancellable = new Cancellable ();
        generator = new SimpleRandomGameGenerator (dimensions, cancellable);
        generator.grade = generator_grade;

        game_name = _("Random pattern");
        view.game_grade = Difficulty.UNDEFINED;
        view.show_working (cancellable, "Generating");
        start_generating (cancellable, generator);
    }

    private void start_generating (Cancellable cancellable, AbstractGameGenerator gen) {
        new Thread<void*> (null, () => {
            var success = gen.generate ();
            /* Gtk is not thread-safe so must invoke in the main loop */
            MainContext.@default ().invoke (() => {
                if (success) {
                    model.set_solution_from_array (gen.get_solution ());
                    game_state = GameState.SOLVING;
                    view.update_labels_from_solution ();
                    view.game_grade = gen.solution_grade;
                } else {
                    clear ();
                    game_state = GameState.SETTING;
                    if (cancellable.is_cancelled ()) {
                       view.send_notification (_("Game generation was cancelled"));
                    } else {
                        view.send_notification (_("Failed to generate game of required grade"));
                    }
                }

                view.end_working ();
                generator = null;

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

        if (temporary_game_path != null) {
            try {
                var current_game = File.new_for_path (temporary_game_path);
                current_game.@delete ();
            } catch (GLib.Error e) {
                warning ("Error deleting temporary game file %s - %s", temporary_game_path, e.message);
            } finally {
                /* Save solution and current state */
                history.to_string ();
                write_game (temporary_game_path, true);
            }
        }
    }

    private void save_settings () {
        if (settings == null) {
            return;
        }

        settings.set_string ("save-game-dir", save_game_dir ?? "");
        settings.set_string ("load-game-dir", load_game_dir ?? "");
    }

    private void restore_settings () {
        if (settings != null) {
            var rows = settings.get_uint ("rows");
            var cols = settings.get_uint ("columns");
            dimensions = {cols, rows};

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
        } else {
            critical ("Unable to restore settings - using defaults");
            /* Default puzzle parameters */
            dimensions = {15, 10};
            game_state = GameState.SETTING;
            generator_grade = Difficulty.MODERATE;
        }
    }

    private async bool restore_game () {
        if (temporary_game_path != null) {
            var current_game = File.new_for_path (temporary_game_path);
            return yield load_game (current_game, false);
        } else {
            return false;
        }
    }

    private string? write_game (string? path, bool save_state = false) {
        Filewriter? file_writer = null;
        var gs = game_state;
        game_state = GameState.UNDEFINED;

        try {
            file_writer = new Filewriter (window,
                                          save_game_dir,
                                          path,
                                          game_name,
                                          dimensions,
                                          view.get_row_clues (),
                                          view.get_col_clues (),
                                          history
                                        );

            file_writer.difficulty = view.game_grade;
            file_writer.game_state = gs;
            file_writer.working.copy (model.working_data);
            file_writer.solution.copy (model.solution_data);
            file_writer.is_readonly = is_readonly;

            if (save_state) {
                file_writer.write_position_file ();
            } else {
                file_writer.write_game_file ();
            }

        } catch (IOError e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = Path.get_basename (file_writer.game_path);
                Utils.show_error_dialog (_("Unable to save %s").printf (basename), e.message);
            }

            return null;
        } finally {
            game_state = gs;
        }

        return file_writer.game_path;
    }

    private async bool load_game (File? game, bool update_load_dir) {
        Filereader? reader = null;
        var gs = game_state;
        game_state = GameState.UNDEFINED;
        clear_history ();

        try {
            reader = new Filereader (window, load_game_dir, game);
        } catch (GLib.IOError e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = game != null ? game.get_basename () : _("game");

                if (reader != null && reader.game_file != null) {
                    basename = reader.game_file.get_basename ();
                }

                /* Avoid error dialog on first run */
                if (basename != Gnonograms.UNSAVED_FILENAME) {
                   Utils.show_error_dialog (_("Unable to load %s").printf (basename), e.message, window);
                }
            }

            return false;
        } finally {
            game_state = gs;
        }

        if (reader.valid && (yield load_common (reader))) {
            if (update_load_dir) {
                /* At this point, we can assume game_file exists and has parent */
                load_game_dir = reader.game_file.get_parent ().get_uri ();
            }

            if (reader.state != GameState.UNDEFINED) {
                game_state = reader.state;
            } else {
                game_state = GameState.SOLVING;
            }

            history.from_string (reader.moves);
            make_move (history.get_current_move ());

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
                dimensions = {reader.cols, reader.rows};
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
            view.game_grade = reader.difficulty;
            model.set_solution_data_from_string_array (reader.solution[0 : rows]);
        } else {
            yield start_solving (false, true); // Sets difficulty in header bar; copies any solution found to solution grid.
        }

        if (reader.name.length > 1 && reader.name != "") {
            game_name = reader.name;
        }

        if (reader.has_working) {
            model.set_working_data_from_string_array (reader.working[0 : rows]);
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
        history.record_move (cell, previous_state);

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

    private uint rewind_until_correct () {
        var errors = model.count_errors ();

        while (model.count_errors () > 0 && on_previous_move_request ()) {
            continue;
        }

        if (model.count_errors () > 0) { // Only happens for completed erroneous solution without history.
            model.blank_working (); // have to restart solving
            clear_history (); // just in case - should not be necessary.
        }

        return errors;
    }

    private void make_move (Move? mv) {
        if (mv == null) {
            return;
        }

        model.set_data_from_cell (mv.cell);

        view.make_move (mv);
    }

    private void clear_history () {
        history.clear_all ();
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
    private void on_moved (Cell cell) {
        var prev_state = model.get_data_for_cell (cell);
        model.set_data_from_cell (cell);

        if (prev_state != cell.state) {
            record_move (cell, prev_state);
        }
    }

    private bool on_next_move_request () {
        if (history.can_go_forward) {
            make_move (history.pop_next_move ());
            return true;
        } else {
            return false;
        }
    }

    private bool on_previous_move_request () {
        if (history.can_go_back) {
            make_move (history.pop_previous_move ());
            return true;
        } else {
            return false;
        }
    }

    private bool on_view_deleted () {
        quit ();
        return false;
    }

    private void on_save_game_request () {
        if (is_readonly) {
            on_save_game_as_request ();
        } else {
            var path = write_game (current_game_path, false);

            if (path != null && path != "") {
                current_game_path = path;
                notify_saved (path);
            }
        }
    }

    private void on_save_game_as_request () {
        /* Filewriter will request save location, no solution saved as default */
        var path = write_game (null, false);

        if (path != null) {
            current_game_path = path;
            notify_saved (path);
            is_readonly = false;
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
        solver = new Solver (dimensions, cancellable);

        new Thread<void*> (null, () => {
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

                if (solver.state.solved ()) {
                    game_state = GameState.SOLVING;
                    if (copy_to_solution) {
                        model.solution_data.copy (solver.grid);
                    }
                }

                if (copy_to_working) {
                    model.working_data.copy (solver.grid);
                }

                view.end_working ();
                start_solving.callback (); // Needed to continue after yield;
                return false;
            });

            return null;
        });

        yield;

        solver = null;
        return state;
    }

    private void on_restart_request () {
        if (game_state == GameState.SETTING) {
            new_game ();
        } else {
            model.blank_working ();
            clear_history ();
        }

        view.update_labels_complete ();
        view.queue_draw ();
    }
}
}
