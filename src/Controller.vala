/* Controller class for gnonograms - creates model and view, handles user input and settings.
 * Copyright (C) 2010-2021  Jeremy Wootten
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
/*** Controller class is created by the Application class. It coordinates all other classes and
   * provides business logic. Most of its properties and functions are private.
***/
public class Gnonograms.Controller : GLib.Object {
/** PUBLIC SIGNALS, PROPERTIES, FUNCTIONS AND CONSTRUCTOR **/
    public signal void quit_app ();

    public Gtk.Window window { get { return (Gtk.Window)view;}}
    public GameState game_state { get; set; }
    public Dimensions dimensions { get; set; }
    public Difficulty generator_grade { get; set; }
    public string game_name { get; set; }

    /* Any game that was not saved by this app is regarded as read only - any alterations
     * must be "Saved As" - which by default is writable. */
    public bool is_readonly { get; set; default = false;}

    private View view;
    private Model model;
    private Solver? solver;
    private SimpleRandomGameGenerator? generator;
    private GLib.Settings? settings;
    private GLib.Settings? saved_state;
    private Gnonograms.History history;
    private string current_game_path;
    private string saved_games_folder;
    private string? temporary_game_path = null;

    private bool is_solving { get { return game_state == GameState.SOLVING;}}
    private uint rows {get { return dimensions.rows ();}}
    private uint cols {get { return dimensions.cols ();}}

    construct {
        game_name = _(UNTITLED_NAME);
        model = new Model ();
        view = new View (model, this);
        history = new Gnonograms.History ();

        view.changed_cell.connect (on_changed_cell);
        view.next_move_request.connect (on_next_move_request);
        view.previous_move_request.connect (on_previous_move_request);
        view.rewind_request.connect (rewind_until_correct);
        view.delete_event.connect (on_view_deleted);
        view.save_game_request.connect (on_save_game_request);
        view.save_game_as_request.connect (on_save_game_as_request);
        view.open_game_request.connect (on_open_game_request);
        view.solve_this_request.connect (on_solve_this_request);
        view.restart_request.connect (on_restart_request);
        view.hint_request.connect (on_hint_request);
#if 0
        view.debug_request.connect (on_debug_request);
#endif
        notify["game-state"].connect (() => {
            if (game_state != GameState.UNDEFINED) { /* Do not clear on save */
                clear_history ();
            }

            if (game_state == GameState.GENERATING) {
                on_new_random_request ();
            }
        });

        notify["dimensions"].connect (() => {
            solver = new Solver (dimensions);
            game_name = _(UNTITLED_NAME);
        });

        var schema_source = GLib.SettingsSchemaSource.get_default ();
        if (schema_source != null &&
            schema_source.lookup ("com.github.jeremypw.gnonograms.settings", true) != null &&
            schema_source.lookup ("com.github.jeremypw.gnonograms.saved-state", true) != null) {

            settings = new Settings ("com.github.jeremypw.gnonograms.settings");
            saved_state = new Settings ("com.github.jeremypw.gnonograms.saved-state");
        }

        var data_home_folder_current = Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_config_dir (),
            "unsaved"
        );

        try {
            var file = File.new_for_path (data_home_folder_current);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Error making %s: %s", data_home_folder_current, e.message);
            }
        }

        saved_games_folder = Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_data_dir (),
            _("Saved Games")
        );
        try {
            var file = File.new_for_path (saved_games_folder);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Error making %s: %s", saved_games_folder, e.message);
            }
        }

        current_game_path = null;
        temporary_game_path = Path.build_path (
            Path.DIR_SEPARATOR_S,
            data_home_folder_current,
            Gnonograms.UNSAVED_FILENAME
        );

        restore_settings ();
        bind_property ("dimensions", model, "dimensions", BindingFlags.SYNC_CREATE);
        bind_property ("dimensions", view, "dimensions", BindingFlags.BIDIRECTIONAL);
        bind_property ("generator-grade", view, "generator-grade", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        bind_property ("game-state", model, "game-state");
        bind_property ("game-state", view, "game-state", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        bind_property ("is-readonly", view, "readonly", BindingFlags.SYNC_CREATE);

        history.bind_property ("can-go-back", view, "can-go-back", BindingFlags.SYNC_CREATE);
        history.bind_property ("can-go-forward", view, "can-go-forward", BindingFlags.SYNC_CREATE);

        if (saved_state != null && settings != null) {
            saved_state.bind ("mode", this, "game_state", SettingsBindFlags.DEFAULT);
            /* Delay binding font-height so can be applied after loading game */
            settings.bind ("grade", this, "generator_grade", SettingsBindFlags.DEFAULT);
            settings.bind ("clue-help", view, "strikeout-complete", SettingsBindFlags.DEFAULT);

            var fh = saved_state.get_double ("font-height");
            saved_state.bind ("font-height", view, "fontheight", SettingsBindFlags.DEFAULT);
            view.fontheight = fh; /* Ensure restored fontheight applied */
        }

        restore_game.begin ((obj, res) => {
            if (!restore_game.end (res)) {
                /* Error normally thrown if running without installing */
                warning ("Restoring game failed");
                restore_dimensions ();
                new_game ();
            }
        });

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

        quit_app ();
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
        game_name = _(UNTITLED_NAME);
    }

    private void on_new_random_request () {
        clear ();
        solver.cancel ();

        var cancellable = new Cancellable ();
        solver.cancellable = cancellable;
        generator = new SimpleRandomGameGenerator (dimensions, solver) {
            grade = generator_grade
        };
        game_name = _("Random pattern");
        view.game_grade = Difficulty.UNDEFINED;

        view.show_working (cancellable, (_("Generating")));
        generator.generate.begin ((obj, res) => {
            var success = generator.generate.end (res);
            if (success) {
                    model.set_solution_from_array (generator.get_solution ());
                    game_state = GameState.SOLVING;
                    view.update_labels_from_solution ();
                    view.game_grade = generator.solution_grade;
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
        });
    }

    private void save_game_state () {
        if (saved_state != null) {
            int x, y;
            window.get_position (out x, out y);
            saved_state.set_int ("window-x", x);
            saved_state.set_int ("window-y", y);

            if (current_game_path != null) {
                saved_state.set_string ("current-game-path", current_game_path);
            }
        }

        if (temporary_game_path != null) {
            try {
                var current_game_path = File.new_for_path (temporary_game_path);
                current_game_path.@delete ();
            } catch (GLib.Error e) {
                /* Error normally thrown on first run */
                debug ("Error deleting temporary game file %s - %s", temporary_game_path, e.message);
            } finally {
            warning ("writing unsaved game to %s", temporary_game_path);
                /* Save solution and current state */
                write_game (temporary_game_path, true);
            }
        } else {
            warning ("No temporary game path");
        }
    }

    private void restore_settings () {
        if (settings != null) {
            int x, y;
            x = saved_state.get_int ("window-x");
            y = saved_state.get_int ("window-y");
            current_game_path = saved_state.get_string ("current-game-path");
            window.move (x, y);
        } else {
            /* Error normally thrown running uninstalled */
            debug ("Unable to restore settings - using defaults"); /* Maybe running uninstalled */
            /* Default puzzle parameters */
            current_game_path = temporary_game_path;
            game_state = GameState.SOLVING;
            generator_grade = Difficulty.MODERATE;
        }

        restore_dimensions ();
    }

    private void restore_dimensions () {
        if (settings != null) {
            dimensions = {
                settings.get_uint ("columns").clamp (10, 50),
                settings.get_uint ("rows").clamp (10, 50)
            };
        } else {
            dimensions = {15, 10}; /* Fallback dimensions */
        }
    }

    private async bool restore_game () {
        if (temporary_game_path != null) {
            var current_game_file = File.new_for_path (temporary_game_path);
            return yield load_game_async (current_game_file);
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
                                          dimensions,
                                          model.get_row_clues (),
                                          model.get_col_clues (),
                                          history
                                        );

            file_writer.difficulty = view.game_grade;
            file_writer.game_state = gs;
            file_writer.working = model.copy_working_data ();
            file_writer.solution = model.copy_solution_data ();
            file_writer.is_readonly = is_readonly;

            if (save_state) {
                file_writer.write_position_file (saved_games_folder, path, game_name);
            } else {
                file_writer.write_game_file (saved_games_folder, path, game_name);
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

    public void load_game (File? game) {
        load_game_async.begin (game, (obj, res) => {
            if (!load_game_async.end (res)) {
                warning ("Load game failed");
                restore_dimensions ();
                new_or_random_game ();
            }
        });
    }

    private async bool load_game_async (File? game) {
        Filereader? reader = null;
        var gs = game_state;

        game_state = GameState.UNDEFINED;
        clear_history ();
        try {
            reader = new Filereader (window, Environment.get_user_data_dir (), game);
        } catch (GLib.Error e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = game != null ? game.get_basename () : _("game");
                string? game_path = null;
                if (reader != null && reader.game_file != null) {
                    basename = reader.game_file.get_basename ();
                    game_path = reader.game_file.get_uri ();
                }
                /* Avoid error dialog on first run */
                if (basename != Gnonograms.UNSAVED_FILENAME) {
                    view.send_notification (
                        _("Error when loading game %s: %s").printf (
                            game_path != null ? game_path : basename, e.message
                    ));
                }
            }

            return false;
        } finally {
            game_state = gs;
        }

        if (reader.valid && (yield load_common (reader))) {
            if (reader.state != GameState.UNDEFINED) {
                game_state = reader.state;
            } else {
                game_state = GameState.SOLVING;
            }

            history.from_string (reader.moves);
            if (history.can_go_back) {
                make_move (history.get_current_move ());
            }
        } else {
            view.send_notification (_("Unable to load game. %s").printf (reader.err_msg));
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

        if (reader.has_solution) {
            view.game_grade = reader.difficulty;
        } else if (reader.has_row_clues && reader.has_col_clues) {
            view.update_labels_from_string_array (reader.row_clues, false);
            view.update_labels_from_string_array (reader.col_clues, true);
        } else {
            reader.err_msg = (_("Clues missing"));
            return false;
        }

        Idle.add (() => { // Need time for model to update dimensions through notify signal
            model.blank_working (); // Do not reveal solution on load
            model.set_solution_data_from_string_array (reader.solution[0 : rows]);

            if (reader.name.length > 1 && reader.name != "") {
                game_name = reader.name;
            }

            if (reader.has_working) {
                model.set_working_data_from_string_array (reader.working[0 : rows]);
            }

            view.update_labels_from_solution (); /* Ensure completeness correctly set */
            return Source.REMOVE;
        });

        is_readonly = reader.is_readonly;
        if (reader.original_path != null && reader.original_path != "") {
            current_game_path = reader.original_path;
        } else {
            current_game_path = reader.game_file.get_path ();
        }

        return true;
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

        if (errors > 0) {
            view.send_notification (
                (ngettext (_("%u error found"), _("%u errors found"), errors)).printf (errors)
            );
        }

        return errors;
    }

    private void make_move (Move mv) {
        view.make_move (mv);
    }

    private void clear_history () {
        history.clear_all ();
    }

    private bool computer_hint () {
        string[] row_clues;
        string[] col_clues;
        row_clues = model.get_row_clues ();
        col_clues = model.get_col_clues ();

        solver.configure_from_grade (Difficulty.CHALLENGING);

        var moves = solver.hint (row_clues, col_clues, model.copy_working_data ());
        foreach (Move mv in moves) {
            make_move (mv);
            history.record_move (mv.cell, mv.previous_state);
        }

        return moves.size > 0;
    }

    private void on_changed_cell (Cell cell, CellState previous_state) {
        history.record_move (cell, previous_state);
        /* Check if puzzle finished */
        if (is_solving && model.is_finished) {
            if (model.count_errors () == 0) {
                ///TRANSLATORS: "Correct" is used as an adjective, indicating that a correct (valid) solution has been found.
                view.send_notification (_("Correct solution"));
            } else if (model.working_matches_clues ()) {
                view.send_notification (_("Alternative solution found"));
            } else {
                view.send_notification (_("There are errors"));
            }

            view.end_working ();
        } else if (!is_solving) {
            solver.state = SolverState.UNDEFINED;
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
        if (is_readonly || current_game_path == temporary_game_path) {
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
        load_game_async.begin (null); /* Filereader will request load location */
    }

    private void on_solve_this_request () {
        game_state = GameState.SOLVING;
        start_solving.begin (true);
    }

    private void on_hint_request () {
        if (game_state != GameState.SOLVING) {
            return;
        }

        if (model.count_errors () > 0) {
            rewind_until_correct ();
        } else if (!computer_hint () && !solver.solved ()) {
            view.send_notification (
                 _("Failed to find a hint using simple logic - multi-line logic (trial and error) required"));
        }
    }

#if 0
    private void on_debug_request (uint idx, bool is_column) {
        if (game_state != GameState.SOLVING) {
            return;
        }

        string[] row_clues;
        string[] col_clues;
        row_clues = model.get_row_clues ();
        col_clues = model.get_col_clues ();

        solver.configure_from_grade (Difficulty.CHALLENGING);

        var moves = solver.debug (idx, is_column, row_clues, col_clues, model.copy_working_data ());
        foreach (Move mv in moves) {
            make_move (mv);
            history.record_move (mv.cell, mv.previous_state);
        }
    }
#endif

    private async SolverState start_solving (bool copy_to_working = false, bool copy_to_solution = false) {
        /* Try as hard as possible to find solution, regardless of grade setting */
        var state = SolverState.UNDEFINED;
        var cancellable = new Cancellable ();
        Difficulty diff = Difficulty.UNDEFINED;
        string msg = "";

        solver.cancel ();
        solver.cancellable = cancellable;
        view.show_working (cancellable, (_("Solving")));
        solver.configure_from_grade (Difficulty.COMPUTER);
        diff = yield solver.solve_clues (model.get_row_clues (), model.get_col_clues ());
        if (cancellable != null && cancellable.is_cancelled ()) {
            msg = _("Solving was cancelled");
        } else if (solver.state.solved ()) {
            ///TRANSLATORS:  Do not translate '%s'. It is a placeholder
            msg = _("Solution found. %s").printf (diff.to_string ());
        } else {
            msg = _("No solution found");
        }

        if (msg != "") {
            view.send_notification (msg);
        }

        view.game_grade = diff;
        if (solver.state.solved ()) {
            game_state = GameState.SOLVING;
            if (copy_to_solution) {
                model.copy_to_solution_data (solver.grid);
            }
        }

        if (copy_to_working) {
            model.copy_to_working_data (solver.grid);
        }

        view.end_working ();
        return state;
    }

    private void on_restart_request () {
        if (game_state == GameState.SETTING) {
            new_game ();
        } else {
            model.blank_working ();
            clear_history ();
        }

        view.end_working ();
    }
}
