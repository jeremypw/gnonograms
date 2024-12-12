/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.View : Gtk.ApplicationWindow {
    public static View get_default () {
        if (instance == null) {
            instance = new View ();
        }

        return instance;
    }

    private static View? instance = null;

    private const uint PROGRESS_DELAY_MSEC = 500;
    private const int DEFAULT_WIDTH = 900;
    private const int DEFAULT_HEIGHT = 700;
    private const uint DARK = Granite.Settings.ColorScheme.DARK;

    public static Gee.MultiMap<string, string> action_accelerators;
    private static GLib.ActionEntry [] view_action_entries = {
        {ACTION_UNDO, action_undo},
        {ACTION_REDO, action_redo},
        {ACTION_CURSOR_UP, action_cursor_up},
        {ACTION_CURSOR_DOWN, action_cursor_down},
        {ACTION_CURSOR_LEFT, action_cursor_left},
        {ACTION_CURSOR_RIGHT, action_cursor_right},
        {ACTION_SETTING_MODE, action_setting_mode},
        {ACTION_SOLVING_MODE, action_solving_mode},
        {ACTION_GENERATING_MODE, action_generating_mode},
        {ACTION_OPEN, action_open},
        {ACTION_SAVE, action_save},
        {ACTION_SAVE_AS, action_save_as},
        {ACTION_CHECK_ERRORS, action_check_errors},
        {ACTION_RESTART, action_restart},
        {ACTION_COMPUTER_SOLVE, action_computer_solve},
        {ACTION_HINT, action_hint},
        {ACTION_OPTIONS, action_options},
        {ACTION_PREFERENCES, action_preferences},
        {ACTION_ZOOM_SMALLER, action_zoom_smaller},
        {ACTION_ZOOM_DEFAULT, action_zoom_default},
        {ACTION_ZOOM_LARGER, action_zoom_larger},
        {ACTION_SHORTCUT_WINDOW, action_shortcut_window},
        {ACTION_ABOUT_WINDOW, action_about_dialog}
    };

#if WITH_DEBUGGING
    public signal void debug_request (uint idx, bool is_column);
#endif

    public SimpleActionGroup view_actions { get; construct; }

    public Cell? current_cell { get; set; }
    public Cell? previous_cell { get; set; }
    // public Difficulty generator_grade { get; set; }
    // public Difficulty game_grade { get; set; }
    public bool readonly { get; set; default = false;}
    public bool restart_destructive { get; set; default = false;}

    private Controller controller = Controller.get_default ();
    private Model model = Model.get_default ();
    private ClueBox row_clue_box;
    private ClueBox column_clue_box;
    private CellGrid cell_grid;
    private Gtk.MenuButton menu_button;
    private HeaderBarManager headerbar_manager;
    private Gtk.Grid main_grid;
    private Adw.ToastOverlay toast_overlay;
    private uint drawing_with_key = 0;
    private CellState drawing_with_state = INVALID;
    private uint paint_fill_key = Gdk.keyval_from_name ("f");
    private uint paint_empty_key = Gdk.keyval_from_name ("e");
    private uint paint_unknown_key = Gdk.keyval_from_name ("x");

    private View () {}

    static construct {
        action_accelerators = new Gee.HashMultiMap<string, string> ();

#if WITH_DEBUGGING
        warning ("WITH DEBUGGING");
        view_action_entries += ActionEntry () {
            name = ACTION_DEBUG_ROW,
            activate = action_debug_row
        };
        view_action_entries += ActionEntry () {
            name = ACTION_DEBUG_COL,
            activate = action_debug_col
        };
#endif
        action_accelerators.set (ACTION_UNDO, "<Ctrl>Z");
        action_accelerators.set (ACTION_REDO, "<Ctrl><Shift>Z");
        action_accelerators.set (ACTION_CURSOR_UP, "Up");
        action_accelerators.set (ACTION_CURSOR_DOWN, "Down");
        action_accelerators.set (ACTION_CURSOR_LEFT, "Left");
        action_accelerators.set (ACTION_CURSOR_RIGHT, "Right");
        action_accelerators.set (ACTION_SETTING_MODE, "<Ctrl>1");
        action_accelerators.set (ACTION_SOLVING_MODE, "<Ctrl>2");
        action_accelerators.set (ACTION_GENERATING_MODE, "<Ctrl>3");
        action_accelerators.set (ACTION_GENERATING_MODE, "<Ctrl>N");
        action_accelerators.set (ACTION_OPEN, "<Ctrl>O");
        action_accelerators.set (ACTION_SAVE, "<Ctrl>S");
        action_accelerators.set (ACTION_SAVE_AS, "<Ctrl><Shift>S");
        action_accelerators.set (ACTION_CHECK_ERRORS, "F7");
        action_accelerators.set (ACTION_RESTART, "F5");
        action_accelerators.set (ACTION_RESTART, "<Ctrl>R");
        action_accelerators.set (ACTION_HINT, "F9");
        action_accelerators.set (ACTION_HINT, "<Ctrl>H");
        action_accelerators.set (ACTION_COMPUTER_SOLVE, "<Alt>S");
        action_accelerators.set (ACTION_OPTIONS, "F10");
        action_accelerators.set (ACTION_OPTIONS, "Menu");
        action_accelerators.set (ACTION_PREFERENCES, "<Ctrl>P");
        action_accelerators.set (ACTION_SHORTCUT_WINDOW, "<Ctrl>K");
        action_accelerators.set (ACTION_SHORTCUT_WINDOW, "F1");
        action_accelerators.set (ACTION_ZOOM_LARGER, "<Ctrl>plus");
        action_accelerators.set (ACTION_ZOOM_LARGER, "<Ctrl>equal");
        action_accelerators.set (ACTION_ZOOM_DEFAULT, "<Ctrl>0");
        action_accelerators.set (ACTION_ZOOM_SMALLER, "<Ctrl>minus");
#if WITH_DEBUGGING
        action_accelerators.set (ACTION_DEBUG_ROW, "<Alt>R");
        action_accelerators.set (ACTION_DEBUG_COL, "<Alt>C");
#endif

    }

    construct {
        var app = (Gnonograms.App) Application.get_default ();
        title = _("Gnonograms");
        set_default_size (DEFAULT_WIDTH, DEFAULT_HEIGHT);
        var view_actions = new GLib.SimpleActionGroup ();
        view_actions.add_action_entries (view_action_entries, this);
        insert_action_group (ACTION_GROUP, view_actions);

        foreach (var action in action_accelerators.get_keys ()) {
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;

            app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }

        headerbar_manager = new HeaderBarManager (this);

        set_titlebar (headerbar_manager.get_headerbar ());

        row_clue_box = new ClueBox (false);
        column_clue_box = new ClueBox (true);
        cell_grid = new CellGrid ();

        cell_grid.bind_property ("cell-width", column_clue_box, "cell-size");
        cell_grid.bind_property ("cell-height", row_clue_box, "cell-size");

        main_grid = new Gtk.Grid () {
            focusable = true, // Needed for key controller to work
            row_spacing = 6,
            column_spacing = 6,
            margin_start = 6,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6
        };

        main_grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues for dimensions.height*/
        main_grid.attach (column_clue_box, 1, 0, 1, 1); /* Clues for columns */
        main_grid.attach (cell_grid, 1, 1, 1, 1);

        toast_overlay = new Adw.ToastOverlay () {
            child = main_grid
        };

        child = toast_overlay;

        var key_controller = new Gtk.EventControllerKey ();
        main_grid.add_controller (key_controller);

        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == paint_fill_key) {
                paint_filled ();
            } else if (keyval == paint_empty_key) {
                paint_empty ();
            } else if (keyval == paint_unknown_key) {
                paint_unknown ();
            } else {
                return false;
            }

            return true;
        });

        key_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == drawing_with_key) {
                stop_painting ();
            }
        });

        var button_controller = new Gtk.GestureClick ();
        button_controller.set_button (0); // Listen to any button
        main_grid.add_controller (button_controller);
        button_controller.pressed.connect ((n_press, x, y) => {
            var button = button_controller.get_current_button ();
            var shift = (SHIFT_MASK in button_controller.get_current_event_state ());
            var set_unknown = (n_press == 2 || button == Gdk.BUTTON_MIDDLE);
            var set_empty = (button == Gdk.BUTTON_SECONDARY || button == Gdk.BUTTON_PRIMARY && shift);

            if (set_unknown) { // Clear current cell
                drawing_with_state = controller.game_state == SOLVING ? CellState.UNKNOWN : CellState.EMPTY;
            } else { // Paint current cell
                drawing_with_state = set_empty ? CellState.EMPTY : CellState.FILLED;
            }

            make_move_at_cell ();
        });
        button_controller.released.connect ((n_press, x, y) => {
            stop_painting ();
        });

        current_cell = Cell () { row = 0, col = 0, state = UNKNOWN };
        previous_cell = current_cell.clone ();

        bind_property (
            "current-cell",
            cell_grid, "current-cell",
            BindingFlags.BIDIRECTIONAL
        );
        bind_property (
            "previous-cell",
            cell_grid, "previous-cell",
            BindingFlags.BIDIRECTIONAL
        );

        controller.notify["game-state"].connect (on_game_state_changed);
        // controller.notify["current-game-path"].connect (update_title);
        // notify["game-grade"].connect (update_title);

        notify["current-cell"].connect (() => {
            highlight_labels (previous_cell, false);
            highlight_labels (current_cell, true);
            if (current_cell != null &&
                drawing_with_state != CellState.INVALID) {

                make_move_at_cell ();
            }
        });

        cell_grid.leave.connect (() => {
            row_clue_box.unhighlight_all ();
            column_clue_box.unhighlight_all ();
        });

        update_style ();
        settings.changed["follow-system-style"].connect (() => {
            update_style ();
        });
        settings.changed["prefer-dark-style"].connect (() => {
            update_style ();
        });
    }

    private void on_game_state_changed () {
        var gs = controller.game_state;
        update_all_labels_completeness ();
        restart_destructive = !model.is_blank (gs);
        headerbar_manager.on_game_state_changed (gs);
    }


    public string[] get_clues (bool is_column) {
        var label_box = is_column ? column_clue_box : row_clue_box;
        return label_box.get_clue_texts ();
    }

    public void update_clues_from_string_array (string[] clues, bool is_column) {
        var clue_box = is_column ? column_clue_box : row_clue_box;
        var lim = is_column ? controller.rows : controller.columns;

        for (int i = 0; i < lim; i++) {
            clue_box.update_clue_text (i, clues[i]);
        }
    }

    public void update_clues_from_solution () {
        for (int r = 0; r < controller.rows; r++) {
            row_clue_box.update_clue_text (
                r,
                model.get_label_text_from_solution (r, false)
            );
        }

        for (int c = 0; c < controller.columns; c++) {
            column_clue_box.update_clue_text (
                c,
                model.get_label_text_from_solution (c, true)
            );
        }

        update_all_labels_completeness ();
    }

    public void make_move (Move m) requires (m.is_valid ()) {
        update_current_and_model (m.cell.state, m.cell);
    }

    public void send_notification (string text) {
        toast_overlay.add_toast (new Adw.Toast (text));
    }

    public void show_working (Cancellable cancellable, string text = "") {
        cell_grid.frozen = true; // Do not show model updates
        schedule_show_progress (cancellable);
        headerbar_manager.show_working (text);
    }

    public void end_working () {
        cell_grid.frozen = false; // Show model updates again
        if (progress_timeout_id > 0) {
            Source.remove (progress_timeout_id);
            progress_timeout_id = 0;
        }

        headerbar_manager.hide_progress ();

        update_all_labels_completeness ();
    }

    public void on_can_go_changed (bool forward, bool back) {
        headerbar_manager.on_can_go_changed (forward, back);
    }

    private void highlight_labels (Cell? c, bool is_highlight) {
        if (c == null) {
            return;
        }

        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void update_all_labels_completeness () {
        for (int r = 0; r < controller.rows; r++) {
            update_clue_complete (r, false);
        }

        for (int c = 0; c < controller.columns; c++) {
            update_clue_complete (c, true);
        }
    }

    private void update_clue_complete (uint idx, bool is_col) {
        var lbox = is_col ? column_clue_box : row_clue_box;

        if (controller.game_state == GameState.SOLVING) {
            var blocks = Gee.List.empty<Block> ();
            blocks = model.get_complete_blocks_from_working (idx, is_col);
            lbox.update_clue_complete (idx, blocks);
        } else {
            lbox.clear_formatting (idx);
        }
    }

    private void make_move_at_cell (
        CellState state = drawing_with_state,
        Cell? target = current_cell
    ) requires (target != null) {
        var prev_state = model.get_data_for_cell (target);
        var cell = update_current_and_model (state, target);

        if (prev_state != state) {
            controller.after_cell_changed (cell, prev_state);
        }
    }

    private Cell update_current_and_model (CellState state, Cell target) {
        Cell cell = target.clone ();
        cell.state = state;

        model.set_data_from_cell (cell);
        update_current_cell (cell);

        var row = current_cell.row;
        var col = current_cell.col;

        if (controller.game_state == GameState.SETTING) {
            row_clue_box.update_clue_text (
                row,
                model.get_label_text_from_solution (row, false)
            );
            column_clue_box.update_clue_text (
                col,
                model.get_label_text_from_solution (col, true)
            );
        } else {
            update_clue_complete (row, false);
            update_clue_complete (col, true);
        }

        return cell;
    }

    private void update_current_cell (Cell target) {
        previous_cell = current_cell;
        current_cell = target;
    }

    private uint progress_timeout_id = 0;
    private void schedule_show_progress (Cancellable cancellable) {
        progress_timeout_id = Timeout.add_full (
            Priority.HIGH_IDLE,
            PROGRESS_DELAY_MSEC,
            () => {
                headerbar_manager.show_progress (cancellable);
                progress_timeout_id = 0;
                return false;
            }
        );
    }

    private void stop_painting () {
        drawing_with_state = CellState.INVALID;
        drawing_with_key = 0;
    }

    /** Action callbacks **/
    private void action_restart () {
        controller.restart ();
        // if (controller.game_state == GameState.SETTING) {
        //     game_grade = Difficulty.UNDEFINED;
        // }
    }

    private void action_computer_solve () requires (controller.game_state == GameState.SETTING) {
        controller.computer_solve ();
    }

    private void action_hint () {
        controller.hint ();
    }

    private void action_options () {
        menu_button.activate ();
    }

    private void action_preferences () {
        headerbar_manager.popdown_menus ();
        var dialog = new PreferencesDialog () {
            transient_for = this,
            title = _("Preferences")
        };
        dialog.response.connect (() => {
            // Changes mediated by settings schema
            dialog.destroy ();
        });
        dialog.present ();
    }

#if WITH_DEBUGGING
    private void action_debug_row () {
        debug_request (current_cell.row, false);
    }

    private void action_debug_col () {
        debug_request (current_cell.col, true);
    }
#endif

    private void action_undo () {
        controller.previous_move ();
    }

    private void action_redo () {
        controller.next_move ();
    }

    private void action_open () {
        controller.open_game ();
    }

    private void action_save () {
        controller.save_game.begin ();
    }

    private void action_save_as () {
        controller.save_game_as.begin ();
    }

    private void action_zoom_larger () {
        var current_width = this.default_width;
        this.default_width = current_width + current_width / 10;
        var current_height = this.default_height;
        this.default_height = current_height + current_height / 10;
    }

    private void action_zoom_smaller () {
        var current_width = this.default_width;
        this.default_width = current_width - current_width / 10;
        var current_height = this.default_height;
        this.default_height = current_height - current_height / 10;
    }

    private void action_zoom_default () {
        this.default_width = DEFAULT_WIDTH;
        this.default_height = DEFAULT_HEIGHT;
    }

    private void action_shortcut_window () {
        var helper = new ShortcutHelper ();
        helper.show_window ();
    }

    private void action_about_dialog () {
        Gtk.show_about_dialog (
            this,
            "authors", new string[1] {"Jeremy Wootten"},
            "comments", _("An implementation of the Japanese logic puzzle \"Nonograms\" written in Vala, allowing the user to solve computer generated puzzles or design their own."),
            "copyright", _("2010-2024 Jeremy Wootten"),
            "license_type", Gtk.License.LGPL_2_1,
            "logo_icon_name", "com.github.jeremypw.gnonograms",
            "program_name", _("Gnonograms"),
            "translator_credits", "NathanBnm (French)\n André Barata (Portuguese)\n Heimen Stoffels (Dutch)",
            "version", "4.0.0",
            "website", "https://github.com/jeremypw/gnonograms",
            "website_label", "Source Code",
            null
        );
    }

    private void action_check_errors () {
        if (controller.rewind_until_correct () == 0) {
            send_notification (_("No errors"));
        }
    }

    private void action_cursor_up () {
        move_cursor (-1, 0);
    }
    private void action_cursor_down () {
        move_cursor (1, 0);
    }
    private void action_cursor_left () {
        move_cursor (0, -1);
    }
    private void action_cursor_right () {
        move_cursor (0, 1);
    }
    private void move_cursor (int row_delta, int col_delta) {
        if (current_cell == null) {
            update_current_cell ({ 0, 0, CellState.INVALID });
            return;
        }

        var target = Cell () {
            row = current_cell.row + row_delta,
            col = current_cell.col + col_delta,
            state = CellState.INVALID
        };

        if (target.row >= controller.rows ||
            target.col >= controller.columns) {

            return;
        }

        update_current_cell (target);
    }

    private void action_setting_mode () {
        controller.change_mode (SETTING);
    }
    private void action_solving_mode () {
        controller.change_mode (SOLVING);
    }
    private void action_generating_mode () {
        controller.change_mode (GENERATING);
    }

    private void paint_filled () {
        paint_cell_state (CellState.FILLED);
        drawing_with_key = paint_fill_key;
    }
    private void paint_empty () {
        paint_cell_state (CellState.EMPTY);
        drawing_with_key = paint_empty_key;
    }

    private void paint_unknown () {
        paint_cell_state (CellState.UNKNOWN);
        drawing_with_key = paint_unknown_key;
    }
    private void paint_cell_state (CellState cs) {
        if (cs == CellState.UNKNOWN && controller.game_state != GameState.SOLVING) {
            return;
        }

        drawing_with_state = cs;

        make_move_at_cell ();
    }

    // Code based largely on elementary Code app
    private ulong color_scheme_listener_handler_id = 0;
    private void update_style () {
        var gtk_settings = Gtk.Settings.get_default ();
        var granite_settings = Granite.Settings.get_default ();
        var following_system = settings.get_boolean ("follow-system-style");
        disconnect_color_scheme_preference_listener (following_system);
        if (following_system) {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == DARK
            );
            color_scheme_listener_handler_id = granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = (
                    granite_settings.prefers_color_scheme == DARK
                );
            });
        } else {
            gtk_settings.gtk_application_prefer_dark_theme = settings.get_boolean ("prefer-dark-style");
            color_scheme_listener_handler_id = settings.notify["prefers-dark-style"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = settings.get_boolean ("prefer-dark-style");
            });
        }
    }

    private void disconnect_color_scheme_preference_listener (bool following_system) {
        if (color_scheme_listener_handler_id != 0) {
            if (following_system) {
                var granite_settings = Granite.Settings.get_default ();
                granite_settings.disconnect (color_scheme_listener_handler_id);
            } else {
                settings.disconnect (color_scheme_listener_handler_id);
            }

            color_scheme_listener_handler_id = 0;
        }
    }
}
