/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */


public const string UNTITLED_NAME = N_("Untitled");

[Flags]
public enum SaveFlags {
    NONE,
    SAVE_STATE,
    CONFIRM_OVERWRITE
}

public class Gnonograms.Controller : GLib.Object {

    public static Controller get_default () {
        if (instance == null) {
            instance = new Controller ();
            instance.set_model_and_view ();
        }

        return instance;
    }

    private static Controller? instance = null;

    public signal void quit_app ();
    public signal void dimensions_changed (uint rows, uint cols);
    // public signal void changed_dimensions (uint rows, uint cols);

    public Gtk.Window window { get { return (Gtk.Window)view;}}
    public GameState game_state { get; set; } // Stored with game file
    public Difficulty generator_grade { get; set; } // synced with settings
    public uint rows { get; set; } // Stored with game file. Can be set be App Popover
    public uint columns { get; set; } // Stored with game file. Can be set be App Popover
    public string game_name { get; set; default = _(UNTITLED_NAME); } // Can be set be App Popover
    public string current_game_path { get; set; default = ""; } // synced with settings
    // /* Any game that was not saved by this app is regarded as read only - any alterations
    //  * must be "Saved As" - which by default is writable. */
    // public bool is_readonly { get; private set; default = false;} // Stored with game file.

    public bool can_go_back {
        get {
            return history.can_go_back;
        }
    }
    public bool can_go_forward {
        get {
            return history.can_go_forward;
        }
    }
    private  View view;
    private Model model;
    private Solver? solver;
    private SimpleRandomGameGenerator? generator;
    private Gnonograms.History history;
    private string saved_games_folder;
    private string temporary_game_path;
    private Gnonograms.App app = (Gnonograms.App) (Application.get_default ());
    private Dimensions dimensions {
        get {
            return { columns, rows };
        }
    }

    private Controller () {}
    construct {
        history = new History ();

        notify["rows"].connect (on_dimensions_changed);
        notify["columns"].connect (on_dimensions_changed);

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

        saved_games_folder = Environment.get_user_special_dir (UserDirectory.DOCUMENTS);

        current_game_path = "";
        temporary_game_path = Path.build_path (
            Path.DIR_SEPARATOR_S,
            data_home_folder_current,
            Gnonograms.UNSAVED_FILENAME
        );

        saved_state.bind ("mode", this, "game-state", SettingsBindFlags.DEFAULT);
        saved_state.bind ("current-game-path", this, "current-game-path", SettingsBindFlags.DEFAULT);
        settings.bind ("grade", this, "generator-grade", SettingsBindFlags.DEFAULT);
        // settings.bind ("rows", this, "rows", SettingsBindFlags.DEFAULT);
        // settings.bind ("columns", this, "columns", SettingsBindFlags.DEFAULT);

        restore_game.begin ((obj, res) => {
            if (!restore_game.end (res)) {
                /* Error normally thrown if running without installing */
                warning ("Restoring game failed");
                restore_defaults ();
                new_game ();
            }
        });
    }

    protected void set_model_and_view () {
        // Needs to be done after Controller construction complete as they need a controller instance
        model = Model.get_default ();
        view = View.get_default ();

        view.close_request.connect (() => {
            return on_delete_request ();
        });
#if WITH_DEBUGGING
        view.debug_request.connect (on_debug_request);
#endif
        view.present ();

        // TODO limit related to actual monitor dimensions
        view.default_height = saved_state.get_int ("window-height").clamp (64, 768);
        view.default_width = saved_state.get_int ("window-width").clamp (128, 1024);
        /*
        * This is very finicky. Bind size after present else set_titlebar gives us bad sizes
        */
        saved_state.bind ("window-height", view, "default-height", SettingsBindFlags.SET);
        saved_state.bind ("window-width", view, "default-width", SettingsBindFlags.SET);

        bind_property (
            "generator-grade",
            view, "generator-grade",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
        );
        bind_property (
            "is-readonly",
            view, "readonly",
            BindingFlags.SYNC_CREATE
        );

        history.can_go_changed.connect ((forward, back) => {
            view.on_can_go_changed (forward, back);
        });
    }

    private void restore_defaults () {
        rows = 10;
        columns = 15;
        view.game_grade = Difficulty.UNDEFINED;
        game_state = GameState.SETTING;

    }

    private void on_dimensions_changed () {
        solver = new Solver (dimensions);
        game_name = _(UNTITLED_NAME);
        dimensions_changed (rows, columns);
    }

    private void new_or_random_game () {
        if (game_state == GameState.SOLVING && game_name == null) {
            on_new_random_request ();
        } else {
            new_game ();
        }
    }

    public void change_mode (GameState mode) {
        switch (mode) {
            case SETTING:
            case SOLVING:
                clear_history ();
                game_state = mode;
                break;
            case GENERATING:
                on_new_random_request ();
                break;
            default:
                critical ("Unhandled mode change request");
                break;
        }
    }

    public void prepare_quit () {
        if (solver != null) {
            solver.cancel ();
        }
        /* If in middle of generating no defined game to save */
        if (generator == null) {
            app.hold ();
            save_game_state.begin ((obj, res) => {
                if (!save_game_state.end (res)) {
                    critical ("Error saving game state");
                }
                // Always quit for now
                warning ("quitting after save state");
                app.release ();
                app.quit ();
            });
        } else {
            generator.cancel ();
            app.quit ();
        }
    }

    private void clear () {
        model.clear ();
        view.update_clues_from_solution ();
        clear_history ();
        // is_readonly = false;
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
        game_state = GameState.GENERATING;
        view.show_working (cancellable, (_("Generating")));
        generator.generate.begin ((obj, res) => {
            var success = generator.generate.end (res);
            GameState new_game_state;
            if (success) {
                model.set_solution_from_array (generator.get_solution ());
                new_game_state = GameState.SOLVING;
                view.update_clues_from_solution ();
                view.game_grade = generator.solution_grade;
            } else {
                clear ();
                new_game_state = GameState.SETTING;
                if (cancellable.is_cancelled ()) {
                   view.send_notification (_("Game generation was cancelled"));
                } else {
                    view.send_notification (_("Failed to generate game of required grade"));
                }
            }

            view.end_working ();
            game_state = new_game_state;            // app.game_state_changed (new_game_state);

            generator = null;
        });
    }

    // Always saved to temp file, not original
    private async bool save_game_state () {
    warning ("save game state");
        string? saved_file_path = null;
        if (temporary_game_path != null) {
            // try {
            //     var current_game_file = File.new_for_path (temporary_game_path);
            //     current_game_file.@delete (); // Unnecessary?
            // } catch (Error e) {
            //     /* Error normally thrown on first run */
            //     warning ("Error deleting temporary game file %s - %s", temporary_game_path, e.message);
            // } finally {
            //     /* Save solution and current state */
                saved_file_path = yield write_game (temporary_game_path, SaveFlags.SAVE_STATE);
            // }
        }

        return saved_file_path != null;
    }

    // Called by save action
    public async void save_game () {
    warning ("Controller: save game");
        if (current_game_path == "") {
            yield save_game_as ();
        } else {
            warning ("write game - no state");
            var path = yield write_game (current_game_path, SaveFlags.NONE);
            if (path != null && path != "") {
                current_game_path = path;
                notify_saved (path);
            }
        }
    }

    // Called by save_as action
    public async void save_game_as () {
    warning ("Controller: save game as");
        /* Filewriter will request save location, no solution saved as default */
        var path = yield write_game (null, SaveFlags.CONFIRM_OVERWRITE);
        if (path != null) {
            current_game_path = path;
            notify_saved (path);
            // is_readonly = false;
        }
    }

    private async bool restore_game () {
        if (temporary_game_path != null) {
            var current_game_file = File.new_for_path (temporary_game_path);
            warning ("restore game %s", current_game_file.get_path ());
            return yield load_game_async (current_game_file);
        } else {
            return false;
        }
    }

    private async string? write_game (string? save_to_path, SaveFlags flags) requires (saved_games_folder != null) {
        var file_writer = new Filewriter (
            window,
            dimensions,
            view.get_clues (false),
            view.get_clues (true),
            view.game_grade,
            saved_games_folder,
            current_game_path,
            game_name,
            save_to_path

        ) {
            solution = !model.solution_is_blank () ? model.copy_solution_data () : null
        };

        var gs = game_state;
        game_state = LOAD_SAVE;
        try {
            if (SAVE_STATE in flags) {
                yield file_writer.write_position_file (
                    model.copy_working_data (),
                    gs,
                    history
                );
            } else {
                yield file_writer.write_game_file (flags);
            }
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = Path.get_basename (file_writer.game_path);
                Utils.show_error_dialog (
                    _("Unable to save %s").printf (basename),
                    e.message
                );
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
                new_or_random_game ();
            }
        });
    }

    private async bool load_game_async (File? game) {
        Filereader? reader = null;
        clear_history ();
        reader = new Filereader ();
        game_state = LOAD_SAVE;
        try {
            yield reader.read (
                window,
                Environment.get_user_special_dir (UserDirectory.DOCUMENTS),
                game
            );
        } catch (GLib.Error e) {
        warning ("error on reading file %s", e.message);
            if (!(e is IOError.CANCELLED)) {
                var basename = game != null ? game.get_basename () : _("game");
                var game_path = "";
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

            game_state = SOLVING; // Default to solving to hide solution
            return false;
        }
warning ("reader read OK");
        if (reader.valid && (yield load_common (reader))) {
warning ("load common OK");
            if (reader.has_working) {
warning ("has working");
                model.set_working_data_from_string_array (reader.working[0 : dimensions.height]);
            }

            if (reader.has_state) {
warning ("has state %s", reader.state.to_string ());
                game_state = reader.state;
                history.from_string (reader.moves);
                if (history.can_go_back) {
                    view.make_move (history.get_current_move ());
                }
            } else {
                game_state = SOLVING;
            }
        } else {
            view.send_notification (_("Unable to load game. %s").printf (reader.err_msg));
            return false;
        }

        return true;
    }

    private async bool load_common (Filereader reader) {
        view.game_grade = reader.difficulty;
        // is_readonly = reader.is_readonly;

        if (reader.has_dimensions) {
            if (reader.rows > MAXSIZE || reader.cols > MAXSIZE) {
                reader.err_msg = (_("Dimensions too large"));
                return false;
            } else if (reader.rows < MINSIZE || reader.cols < MINSIZE) {
                reader.err_msg = (_("Dimensions too small"));
                return false;
            } else {
                // This will resize model and view as well
                columns = reader.cols;
                rows = reader.rows;
            }
        } else {
            reader.err_msg = (_("Dimensions missing"));
            return false;
        }

        if (reader.has_row_clues && reader.has_col_clues) {
            view.update_clues_from_string_array (reader.row_clues, false);
            view.update_clues_from_string_array (reader.col_clues, true);
        } else {
            reader.err_msg = (_("Clues missing"));
            return false;
        }

        if (reader.name.length > 1 && reader.name != "") {
            game_name = reader.name;
        }


        if (reader.original_path != null && reader.original_path != "") {
            warning ("has original path %s", reader.original_path);
            current_game_path = reader.original_path;
        } else {
            current_game_path = reader.game_file.get_path ();
        }

        Idle.add (() => { // Need time for model to update dimensions through notify signal
            model.blank_working (); // Do not reveal solution on load
            model.blank_solution (); // Do not reveal solution on load

            if (reader.has_solution) {
            warning ("has solution");
                model.set_solution_data_from_string_array (reader.solution[0 : dimensions.height]);
                view.update_clues_from_solution (); /* Ensure completeness correctly set */
            }

            load_common.callback ();
            return Source.REMOVE;
        });

        yield;


warning ("current game path now %s", current_game_path);
        return true;
    }

    public int rewind_until_correct () {
        if (model.solution_is_blank ()) {
            view.send_notification (_("Cannot check for errors.  Solution unknown"));
            return -1;
        }

        var errors = model.count_errors ();

        while (model.count_errors () > 0 && previous_move ()) {
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

    private void clear_history () {
        history.clear_all ();
    }

    private bool computer_hint () {
        string[] row_clues;
        string[] col_clues;
        row_clues = view.get_clues (false);
        col_clues = view.get_clues (true);
        solver.configure_from_grade (Difficulty.CHALLENGING);

        var moves = solver.hint (row_clues, col_clues, model.copy_working_data ());
        foreach (Move mv in moves) {
            view.make_move (mv);
            history.record_move (mv.cell, mv.previous_state);
        }

        return moves.size > 0;
    }

    public void after_cell_changed (Cell cell, CellState previous_state) {
        history.record_move (cell, previous_state);
        /* Check if puzzle finished */
        if (game_state == GameState.SOLVING && !model.solution_is_blank () && model.is_finished) {
            if (model.count_errors () == 0) {
///TRANSLATORS: "Correct" is used as an adjective, indicating that a correct (valid) solution has been found.
                view.send_notification (_("Correct solution"));
            } else if (model.working_matches_clues ()) {
                view.send_notification (_("Alternative solution found"));
            } else {
                view.send_notification (_("There are errors"));
            }

            view.end_working ();
        } else if (game_state != GameState.SOLVING) {
            solver.state = SolverState.UNDEFINED;
        }
    }

    public bool next_move () {
        if (history.can_go_forward) {
            view.make_move (history.pop_next_move ());
            return true;
        } else {
            return false;
        }
    }

    public bool previous_move () {
        if (history.can_go_back) {
            view.make_move (history.pop_previous_move ());
            return true;
        } else {
            return false;
        }
    }

    public bool on_delete_request () {
        warning ("on delete request");
        prepare_quit (); // Async
        warning ("on view deleted returning true");
        return true;
    }

    private void notify_saved (string path) {
        view.send_notification (_("Saved to %s").printf (path));
    }

    public void open_game () {
    warning ("Controller: open game (null)");
        load_game_async.begin (null); /* Filereader will request load location */
    }

    public void computer_solve () {
        start_solving.begin (true);
    }

    public void hint () {
        if (game_state != GameState.SOLVING) {
            return;
        }

        if (!model.solution_is_blank () && model.count_errors () > 0) {
            rewind_until_correct ();
        } else if (!computer_hint () && !solver.solved ()) {
            view.send_notification (
                 _("Failed to find a hint using simple logic - multi-line logic (trial and error) required"));
        }
    }

#if WITH_DEBUGGING
    private void on_debug_request (uint idx, bool is_column) {
        if (game_state != GameState.SOLVING || model.solution_is_blank ()) {
            return;
        }

        string[] row_clues;
        string[] col_clues;
        row_clues = model.get_row_clues ();
        col_clues = model.get_col_clues ();

        solver.configure_from_grade (Difficulty.CHALLENGING);

        var moves = solver.debug (idx, is_column, row_clues, col_clues, model.copy_working_data ());
        foreach (Move mv in moves) {
            view.make_move (mv);
            history.record_move (mv.cell, mv.previous_state);
        }
    }
#endif

    private async SolverState start_solving (
        bool copy_to_working = false,
        bool copy_to_solution = false
    ) {
        /* Try as hard as possible to find solution, regardless of grade setting */
        var state = SolverState.UNDEFINED;
        var cancellable = new Cancellable ();
        Difficulty diff = Difficulty.UNDEFINED;
        string msg = "";

        solver.cancel ();
        solver.cancellable = cancellable;
        view.show_working (cancellable, (_("Solving")));
        solver.configure_from_grade (Difficulty.COMPUTER);
        diff = yield solver.solve_clues (view.get_clues (false), view.get_clues (true));

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
        view.end_working ();
        return state;
    }

    public void restart () {
        if (game_state == GameState.SETTING) {
            new_game ();
        } else {
            model.blank_working ();
            clear_history ();
        }

        view.end_working ();
    }

    public void increase_fontsize () {}
    public void decrease_fontsize () {}
}
