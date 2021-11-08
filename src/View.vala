/* View.vala
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
 *  Author: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.View : Hdy.ApplicationWindow {
    private const double USABLE_MONITOR_HEIGHT = 0.85;
    private const double USABLE_MONITOR_WIDTH = 0.95;
    private const int GRID_BORDER = 6;
    private const int GRID_COLUMN_SPACING = 6;
    private const double TYPICAL_MAX_BLOCKS_RATIO = 0.3;
    private const double ZOOM_RATIO = 0.05;
    private const uint PROGRESS_DELAY_MSEC = 500;

    public signal void random_game_request ();
    public signal uint rewind_request ();
    public signal bool next_move_request ();
    public signal bool previous_move_request ();
    public signal void save_game_request ();
    public signal void save_game_as_request ();
    public signal void open_game_request ();
    public signal void solve_this_request ();
    public signal void restart_request ();
    public signal void hint_request ();
#if WITH_DEBUGGING
    public signal void debug_request (uint idx, bool is_column);
#endif
    public signal void changed_cell (Cell cell, CellState previous_state);

    public Model model {private get; construct; }
    public Controller controller { get; construct; }
    public Dimensions dimensions { get; set; }
    public Cell current_cell { get; set; }
    public Cell previous_cell { get; set; }
    public Difficulty generator_grade { get; set; }
    public Difficulty game_grade { get; set; default = Difficulty.UNDEFINED;}
    public GameState game_state { get; set; }
    public int cell_size { get; set; default = 32; }
    public string game_name { get { return controller.game_name; } }
    public bool strikeout_complete { get; set; }
    public bool readonly { get; set; default = false;}
    public bool can_go_back { get; set; }
    public bool can_go_forward { get; set; }
    public bool restart_destructive { get; set; default = false;}

    public SimpleActionGroup view_actions { get; construct; }
    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    public const string ACTION_GROUP = "win";
    public const string ACTION_PREFIX = ACTION_GROUP + ".";
    public const string ACTION_UNDO = "action-undo";
    public const string ACTION_REDO = "action-redo";
    public const string ACTION_ZOOM_IN = "action-zoom-in";
    public const string ACTION_ZOOM_OUT = "action-zoom-out";
    public const string ACTION_CURSOR_UP = "action-cursor_up";
    public const string ACTION_CURSOR_DOWN = "action-cursor_down";
    public const string ACTION_CURSOR_LEFT = "action-cursor_left";
    public const string ACTION_CURSOR_RIGHT = "action-cursor_right";
    public const string ACTION_SETTING_MODE = "action-setting-mode";
    public const string ACTION_SOLVING_MODE = "action-solving-mode";
    public const string ACTION_GENERATING_MODE = "action-generating-mode";
    public const string ACTION_OPEN = "action-open";
    public const string ACTION_SAVE = "action-save";
    public const string ACTION_SAVE_AS = "action-save-as";
    public const string ACTION_PAINT_FILLED = "action-paint-filled";
    public const string ACTION_PAINT_EMPTY = "action-paint-empty";
    public const string ACTION_PAINT_UNKNOWN = "action-paint-unknown";
    public const string ACTION_CHECK_ERRORS = "action-check-errors";
    public const string ACTION_RESTART = "action-restart";
    public const string ACTION_SOLVE = "action-solve";
    public const string ACTION_HINT = "action-hint";
#if WITH_DEBUGGING
    public const string ACTION_DEBUG_ROW = "action-debug-row";
    public const string ACTION_DEBUG_COL = "action-debug-col";
#endif
    private static GLib.ActionEntry [] VIEW_ACTION_ENTRIES = {
        {ACTION_UNDO, action_undo},
        {ACTION_REDO, action_redo},
        {ACTION_ZOOM_IN, action_zoom_in},
        {ACTION_ZOOM_OUT, action_zoom_out},
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
        {ACTION_PAINT_FILLED, action_paint_filled},
        {ACTION_PAINT_EMPTY, action_paint_empty},
        {ACTION_PAINT_UNKNOWN, action_paint_unknown},
        {ACTION_CHECK_ERRORS, action_check_errors},
        {ACTION_RESTART, action_restart},
        {ACTION_SOLVE, action_solve},
        {ACTION_HINT, action_hint}
    };


    private LabelBox row_clue_box;
    private LabelBox column_clue_box;
    private CellGrid cell_grid;
    private ProgressIndicator progress_indicator;
    private AppMenu app_menu;
    private CellState drawing_with_state = CellState.UNDEFINED;
    private Hdy.HeaderBar header_bar;
    private Granite.Widgets.Toast toast;
    private Granite.ModeSwitch mode_switch;
    private Gtk.Grid main_grid;
    private Gtk.Overlay overlay;
    private Gtk.Stack progress_stack;
    private Gtk.Label title_label;
    private Gtk.Label grade_label;
    private Gtk.Button generate_button;
    private Gtk.Button load_game_button;
    private Gtk.Button save_game_button;
    private Gtk.Button save_game_as_button;
    private Gtk.Button undo_button;
    private Gtk.Button redo_button;
    private Gtk.Button check_correct_button;
    private Gtk.Button hint_button;
    private Gtk.Button auto_solve_button;
    private Gtk.Button restart_button;
    private uint drawing_with_key;
    private int rows { get { return (int) dimensions.rows (); }}
    private int cols { get { return (int) dimensions.cols (); }}
    private bool is_solving { get { return game_state == GameState.SOLVING; }}

    public View (Model _model, Controller controller) {
        Object (
            model: _model,
            controller: controller,
            resizable: false
        );
    }

    static construct {
#if WITH_DEBUGGING
warning ("WITH DEBUGGING");
        VIEW_ACTION_ENTRIES += ActionEntry () { name = ACTION_DEBUG_ROW, activate = action_debug_row };
        VIEW_ACTION_ENTRIES += ActionEntry () { name = ACTION_DEBUG_COL, activate = action_debug_col };
#endif
        action_accelerators.set (ACTION_UNDO, "<Ctrl>Z");
        action_accelerators.set (ACTION_REDO, "<Ctrl><Shift>Z");
        action_accelerators.set (ACTION_CURSOR_UP, "Up");
        action_accelerators.set (ACTION_CURSOR_DOWN, "Down");
        action_accelerators.set (ACTION_CURSOR_LEFT, "Left");
        action_accelerators.set (ACTION_CURSOR_RIGHT, "Right");
        action_accelerators.set (ACTION_ZOOM_IN, "<Ctrl>plus");
        action_accelerators.set (ACTION_ZOOM_IN, "<Ctrl>equal");
        action_accelerators.set (ACTION_ZOOM_IN, "<Ctrl>KP_Add");
        action_accelerators.set (ACTION_ZOOM_OUT, "<Ctrl>minus");
        action_accelerators.set (ACTION_ZOOM_OUT, "<Ctrl>KP_Subtract");
        action_accelerators.set (ACTION_SETTING_MODE, "<Ctrl>1");
        action_accelerators.set (ACTION_SOLVING_MODE, "<Ctrl>2");
        action_accelerators.set (ACTION_GENERATING_MODE, "<Ctrl>3");
        action_accelerators.set (ACTION_GENERATING_MODE, "<Ctrl>N");
        action_accelerators.set (ACTION_OPEN, "<Ctrl>O");
        action_accelerators.set (ACTION_SAVE, "<Ctrl>S");
        action_accelerators.set (ACTION_SAVE_AS, "<Ctrl><Shift>S");
        action_accelerators.set (ACTION_PAINT_FILLED, "F");
        action_accelerators.set (ACTION_PAINT_EMPTY, "E");
        action_accelerators.set (ACTION_PAINT_UNKNOWN, "X");
        action_accelerators.set (ACTION_CHECK_ERRORS, "F7");
        action_accelerators.set (ACTION_CHECK_ERRORS, "less");
        action_accelerators.set (ACTION_CHECK_ERRORS, "comma");
        action_accelerators.set (ACTION_RESTART, "F5");
        action_accelerators.set (ACTION_RESTART, "<Ctrl>R");
        action_accelerators.set (ACTION_HINT, "F9");
        action_accelerators.set (ACTION_HINT, "<Ctrl>H");
#if WITH_DEBUGGING
        action_accelerators.set (ACTION_DEBUG_ROW, "<Alt>R");
        action_accelerators.set (ACTION_DEBUG_COL, "<Alt>C");
#endif

        try {
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("com/github/jeremypw/gnonograms/Application.css");
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            warning ("Error adding css provider: %s", e.message);
        }

        Hdy.init ();
    }

    construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/jeremypw/gnonograms");

        var view_actions = new GLib.SimpleActionGroup ();
        view_actions.add_action_entries (VIEW_ACTION_ENTRIES, this);
        insert_action_group (ACTION_GROUP, view_actions);

        var application = (Gtk.Application)(Application.get_default ());
        foreach (var action in action_accelerators.get_keys ()) {
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;

            application.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }

        header_bar = new Hdy.HeaderBar ();
        header_bar.set_has_subtitle (false);
        header_bar.set_show_close_button (true);
        header_bar.get_style_context ().add_class ("gnonograms-header");

        load_game_button = new HeaderButton ("document-open", _("Load a Game from File")) {
            action_name = ACTION_PREFIX + ACTION_OPEN
        };
        save_game_button = new HeaderButton ("document-save", _("Save Game")) {
            action_name = ACTION_PREFIX + ACTION_SAVE
        };
        save_game_as_button = new HeaderButton ("document-save-as", _("Save Game to Different File")) {
            action_name = ACTION_PREFIX + ACTION_SAVE_AS
        };
        undo_button = new HeaderButton ("edit-undo", _("Undo Last Move")) {
            action_name = ACTION_PREFIX + ACTION_UNDO
        };
        redo_button = new HeaderButton ("edit-redo", _("Redo Last Move")) {
            action_name = ACTION_PREFIX + ACTION_REDO
        };
        check_correct_button = new HeaderButton ("media-seek-backward", _("Go Back to Last Correct Position")) {
            action_name = ACTION_PREFIX + ACTION_CHECK_ERRORS
        };
        restart_button = new RestartButton ("view-refresh", "") {
            action_name = ACTION_PREFIX + ACTION_RESTART
        };
        hint_button = new HeaderButton ("help-contents", _("Suggest next move")) {
            action_name = ACTION_PREFIX + ACTION_HINT
        };
        auto_solve_button = new HeaderButton ("system", _("Solve by Computer")) {
            action_name = ACTION_PREFIX + ACTION_SOLVE
        };
        generate_button = new HeaderButton ("list-add", _("Generate New Puzzle")) {
            action_name = ACTION_PREFIX + ACTION_GENERATING_MODE
        };

        app_menu = new AppMenu (controller);

        mode_switch = new Granite.ModeSwitch.from_icon_name ("edit-symbolic", "head-thinking-symbolic") {
            valign = Gtk.Align.CENTER
        };

        progress_indicator = new ProgressIndicator ();

        title_label = new Gtk.Label ("Gnonograms") {
            use_markup = true,
            xalign = 0.5f
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        title_label.show ();

        grade_label = new Gtk.Label ("Easy") {
            use_markup = true,
            xalign = 0.5f
        };
        grade_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var title_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        title_grid.add (title_label);
        title_grid.add (grade_label);
        title_grid.show_all ();

        progress_stack = new Gtk.Stack ();
        progress_stack.add_named (progress_indicator, "Progress");
        progress_stack.add_named (title_grid, "Title");
        progress_stack.set_visible_child_name ("Title");

        header_bar.pack_start (load_game_button);
        header_bar.pack_start (save_game_button);
        header_bar.pack_start (save_game_as_button);
        header_bar.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_start (restart_button);
        header_bar.pack_start (undo_button);
        header_bar.pack_start (redo_button);
        header_bar.pack_start (check_correct_button);

        header_bar.pack_end (app_menu);
        header_bar.pack_end (auto_solve_button);
        header_bar.pack_end (hint_button);
        header_bar.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_end (generate_button);
        header_bar.pack_end (mode_switch);
        header_bar.set_custom_title (progress_stack);

        toast = new Granite.Widgets.Toast ("") {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        toast.set_default_action (null);

        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL);
        cell_grid = new CellGrid (model);

        main_grid = new Gtk.Grid () {
            row_spacing = 0,
            column_spacing = GRID_COLUMN_SPACING,
            border_width = GRID_BORDER,
            expand = true
        };

        main_grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues for rows */
        main_grid.attach (column_clue_box, 1, 0, 1, 1); /* Clues for columns */
        main_grid.attach (cell_grid, 1, 1, 1, 1);

        var ev = new Gtk.EventBox () {expand = true};
        ev.add_events (Gdk.EventMask.SCROLL_MASK);
        ev.scroll_event.connect (on_grid_scroll_event);
        ev.add (main_grid);

        overlay = new Gtk.Overlay () {
            expand = true
        };
        overlay.add_overlay (toast);
        overlay.add (ev);

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        grid.add (header_bar);
        grid.add (overlay);
        add (grid);

        cell_grid.leave_notify_event.connect (on_grid_leave);
        cell_grid.button_press_event.connect (on_grid_button_press);
        cell_grid.button_release_event.connect (stop_painting);
        key_release_event.connect (on_key_release_event);

        var flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
        bind_property ("restart-destructive", restart_button, "restart-destructive", BindingFlags.SYNC_CREATE) ;
        bind_property ("game-state", mode_switch, "active", flags,
        (binding, src_val, ref tgt_val) => {
            tgt_val.set_boolean (src_val.get_enum () > GameState.SETTING);
        },
        (binding, src_val, ref tgt_val) => {
            tgt_val.set_enum (src_val.get_boolean () ? GameState.SOLVING : GameState.SETTING);
        });
        bind_property ("current-cell", cell_grid, "current-cell", BindingFlags.BIDIRECTIONAL);
        bind_property ("previous-cell", cell_grid, "previous-cell", BindingFlags.BIDIRECTIONAL);
        bind_property ("cell-size", cell_grid, "cell-size", BindingFlags.SYNC_CREATE);
        bind_property ("cell-size", row_clue_box, "cell-size", BindingFlags.SYNC_CREATE);
        bind_property ("cell-size", column_clue_box, "cell-size", BindingFlags.SYNC_CREATE);
        bind_property ("dimensions", row_clue_box, "dimensions");
        bind_property ("dimensions", column_clue_box, "dimensions");

        notify["game-state"].connect (() => {
            if (game_state != GameState.UNDEFINED) {
                update_all_labels_completeness ();
            }

            update_header_bar ();
        });

        notify["generator-grade"].connect (() => {
            ///TRANSLATORS: '%s' is a placeholder for an adjective describing the difficulty of the puzze. It can be moved but not translated.
            generate_button.tooltip_text = _("Generate %s puzzle").printf (generator_grade.to_string ());
        });

        controller.notify["game-name"].connect (() => {
            update_title ();
        });

        notify["game-grade"].connect (() => {
            update_title ();
        });

        notify["readonly"].connect (() => {
            save_game_button.sensitive = readonly;
        });

        notify["can-go-back"].connect (() => {
            check_correct_button.sensitive = can_go_back && is_solving;
            undo_button.sensitive = can_go_back;
            restart_destructive |= can_go_back; /* May be destructive even if no history (e.g. after automatic solve) */
        });

        notify["can-go-forward"].connect (() => {
            redo_button.sensitive = can_go_forward;
        });

        notify["current-cell"].connect (() => {
            highlight_labels (previous_cell, false);
            highlight_labels (current_cell, true);

            if (drawing_with_state != CellState.UNDEFINED) {
                make_move_at_cell ();
            }
        });

        notify["strikeout-complete"].connect (() => {
            update_all_labels_completeness ();
        });

        notify["dimensions"].connect (() => {
            var monitor_area = Gdk.Rectangle () {
                width = 1024,
                height = 768
            };

            Gdk.Window? window = get_window ();
            if (window != null) {
                monitor_area = Utils.get_monitor_area (screen, window);
            }

            var available_grid_width = (int)(get_allocated_width () - 2 * GRID_BORDER - GRID_COLUMN_SPACING);
            var available_cell_width = available_grid_width / (cols * 1.2);
            var available_screen_height = monitor_area.height * 0.85 - header_bar.get_allocated_height () - 2 * GRID_BORDER;

            var available_cell_height = available_screen_height / (rows * 1.2);
            cell_size = (int)(double.min (available_cell_width, available_cell_height));
        });

        show_all ();
    }

    // public const double FONT_ASPECT_RATIO = 1.2;
    public void update_labels_from_string_array (string[] clues, bool is_column) {
        var clue_box = is_column ? column_clue_box : row_clue_box;
        var lim = is_column ? cols : rows;

        for (int i = 0; i < lim; i++) {
            clue_box.update_label_text (i, clues[i]);
        }
    }

    public void update_labels_from_solution () {
        for (int r = 0; r < rows; r++) {
            row_clue_box.update_label_text (r, model.get_label_text_from_solution (r, false));
        }

        for (int c = 0; c < cols; c++) {
            column_clue_box.update_label_text (c, model.get_label_text_from_solution (c, true));
        }

        update_all_labels_completeness ();
    }

    public void make_move (Move m) {
        if (!m.is_null ()) {
            update_current_and_model (m.cell.state, m.cell);
        }
    }

    public void send_notification (string text) {
        toast.title = text.dup ();
        toast.send_notification ();
    }

    public void show_working (Cancellable cancellable, string text = "") {
        cell_grid.frozen = true; // Do not show model updates
        progress_indicator.text = text;
        schedule_show_progress (cancellable);
    }

    public void end_working () {
        cell_grid.frozen = false; // Show model updates again

        if (progress_timeout_id > 0) {
            Source.remove (progress_timeout_id);
            progress_timeout_id = 0;
        } else {
            progress_stack.set_visible_child_name ("Title");
        }

        update_all_labels_completeness ();
        update_header_bar ();
    }

    private void update_header_bar () {
        switch (game_state) {
            case GameState.SETTING:
                restart_button.tooltip_text = _("Clear canvas");
                set_buttons_sensitive (true);

                break;
            case GameState.SOLVING:
                restart_button.tooltip_text = _("Restart solving");
                set_buttons_sensitive (true);

                break;
            case GameState.GENERATING:
                set_buttons_sensitive (false);

                break;
            default:
                break;
        }
    }

    private void update_title () {
        title_label.label = game_name;
        grade_label.label = game_grade.to_string ();
    }

    private void set_buttons_sensitive (bool sensitive) {
        generate_button.sensitive = game_state != GameState.GENERATING;
        mode_switch.sensitive = sensitive;
        load_game_button.sensitive = sensitive;
        save_game_button.sensitive = sensitive;
        save_game_as_button.sensitive = sensitive;
        restart_destructive = sensitive && !model.is_blank (game_state);
        undo_button.sensitive = sensitive && can_go_back;
        redo_button.sensitive = sensitive && can_go_forward;
        check_correct_button.sensitive = sensitive && is_solving && can_go_back;
        hint_button.sensitive = sensitive && game_state == GameState.SOLVING;
        auto_solve_button.sensitive = sensitive;
    }

    private void highlight_labels (Cell c, bool is_highlight) {
        /* If c is NULL_CELL then will unhighlight all labels */
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void update_all_labels_completeness () {
        for (int r = 0; r < rows; r++) {
            update_label_complete (r, false);
        }

        for (int c = 0; c < cols; c++) {
            update_label_complete (c, true);
        }
    }

    private void update_label_complete (uint idx, bool is_col) {
        var lbox = is_col ? column_clue_box : row_clue_box;

        if (game_state == GameState.SOLVING && strikeout_complete) {
            var blocks = Gee.List.empty<Block> ();
            blocks = model.get_complete_blocks_from_working (idx, is_col);
            lbox.update_label_complete (idx, blocks);
        } else {
            lbox.clear_formatting (idx);
        }
    }

    private void make_move_at_cell (CellState state = drawing_with_state, Cell target = current_cell) {
        if (target == NULL_CELL) {
            return;
        }

        var prev_state = model.get_data_for_cell (target);
        var cell = update_current_and_model (state, target);

        if (prev_state != state) {
            changed_cell (cell, prev_state);
        }
    }

    private Cell update_current_and_model (CellState state, Cell target) {
        Cell cell = target.clone ();
        cell.state = state;

        model.set_data_from_cell (cell);
        update_current_cell (cell);

        var row = current_cell.row;
        var col = current_cell.col;

        if (game_state == GameState.SETTING) {
            row_clue_box.update_label_text (row, model.get_label_text_from_solution (row, false));
            column_clue_box.update_label_text (col, model.get_label_text_from_solution (col, true));
        } else {
            update_label_complete (row, false);
            update_label_complete (col, true);
        }

        return cell;
    }

    private void update_current_cell (Cell target) {
        previous_cell = current_cell;
        current_cell = target;
    }

    private uint progress_timeout_id = 0;
    private void schedule_show_progress (Cancellable cancellable) {
        progress_timeout_id = Timeout.add_full (Priority.HIGH_IDLE, PROGRESS_DELAY_MSEC, () => {
            progress_indicator.cancellable = cancellable;
            progress_stack.set_visible_child_name ("Progress");
            progress_timeout_id = 0;
            return false;
        });
    }

    /*** Signal handlers ***/
    private bool on_grid_leave () {
        row_clue_box.unhighlight_all ();
        column_clue_box.unhighlight_all ();
        return false;
    }

    private bool on_grid_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.@2BUTTON_PRESS || event.button == Gdk.BUTTON_MIDDLE) {
            drawing_with_state = is_solving ? CellState.UNKNOWN : CellState.EMPTY;
        } else {
            drawing_with_state = event.button == Gdk.BUTTON_PRIMARY ? CellState.FILLED : CellState.EMPTY;
        }

        make_move_at_cell ();
        return true;
    }

    private bool on_key_release_event (Gdk.EventKey event) {
        if (event.keyval == drawing_with_key) {
            stop_painting ();
        }

        return false;
    }

    private bool stop_painting () {
        drawing_with_state = CellState.UNDEFINED;
        drawing_with_key = 0;
        return false;
    }

    /** With Control pressed, zoom using the fontsize. **/
    private bool on_grid_scroll_event (Gdk.EventScroll event) {
        if (Gdk.ModifierType.CONTROL_MASK in event.state) {
            switch (event.direction) {
                case Gdk.ScrollDirection.UP:
                    change_cell_size (false);
                    break;

                case Gdk.ScrollDirection.DOWN:
                    change_cell_size (true);
                    break;

                default:
                    break;
            }

            return true;
        }

        return false;
    }

    /** Action callbacks **/
    private void action_restart () {
        restart_request ();
        if (game_state == GameState.SETTING) {
            game_grade = Difficulty.UNDEFINED;
        }
    }

    private void action_solve () {
        solve_this_request ();
    }

    private void action_hint () {
        hint_request ();
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
        previous_move_request ();
    }

    private void action_redo () {
        next_move_request ();
    }

    private void action_open () {
        open_game_request ();
    }

    private void action_save () {
        save_game_request ();
    }

    private void action_save_as () {
        save_game_as_request ();
    }

    private void action_zoom_in () {
        change_cell_size (true);
    }
    private void action_zoom_out () {
        change_cell_size (false);
    }

    private void change_cell_size (bool increase) {
        var delta = double.max (ZOOM_RATIO * cell_size, 1.0);
        if (increase) {
            cell_size += (int)delta;
        } else {
            cell_size -= (int)delta;
        }
    }
    private void action_check_errors () {
        if (rewind_request () == 0) {
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
        if (current_cell == NULL_CELL) {
            return;
        }

        Cell target = {current_cell.row + row_delta,
                       current_cell.col + col_delta,
                       CellState.UNDEFINED
                      };

        if (target.row >= rows || target.col >= cols) {
            return;
        }

        update_current_cell (target);
    }

    private void action_setting_mode () {
        game_state = GameState.SETTING;
    }
    private void action_solving_mode () {
        game_state = GameState.SOLVING;
    }
    private void action_generating_mode () {
        game_state = GameState.GENERATING;
    }

    private void action_paint_filled () {
        paint_cell_state (CellState.FILLED);
    }
    private void action_paint_empty () {
        paint_cell_state (CellState.EMPTY);
    }
    private void action_paint_unknown () {
        paint_cell_state (CellState.UNKNOWN);
    }
    private void paint_cell_state (CellState cs) {
        if (cs == CellState.UNKNOWN && !is_solving) {
            return;
        }

        drawing_with_state = cs;
        var current_event = Gtk.get_current_event ();
        if (current_event.type == Gdk.EventType.KEY_PRESS) {
            drawing_with_key = ((Gdk.EventKey)current_event).keyval;
        }

        make_move_at_cell ();
    }

    private class RestartButton : HeaderButton {
        public bool restart_destructive { get; set; }

        construct {
            restart_destructive = false;

            notify["restart-destructive"].connect (() => {
                if (restart_destructive) {
                    image.get_style_context ().add_class ("warn");
                    image.get_style_context ().remove_class ("dim");
                } else {
                    image.get_style_context ().remove_class ("warn");
                    image.get_style_context ().add_class ("dim");

                }
            });

            bind_property ("sensitive", this, "restart-destructive");
        }

        public RestartButton (string icon_name, string tooltip = "", bool sensitive = true) {
            base (icon_name, tooltip, sensitive);
        }
    }

    private class HeaderButton : Gtk.Button {
        construct {
            margin_top = 3;
            margin_bottom = 3;
            valign = Gtk.Align.CENTER;
        }

        public HeaderButton (string icon_name, string tooltip = "", bool sensitive = true) {
            Object (
                image: new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR),
                tooltip_text: tooltip,
                sensitive: sensitive
            );
        }
    }
}
