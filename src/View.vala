/* View.vala
 * Copyright (C) 2010-2022  Jeremy Wootten
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

public class Gnonograms.View : Gtk.ApplicationWindow {
    private const double USABLE_MONITOR_HEIGHT = 0.85;
    private const double USABLE_MONITOR_WIDTH = 0.95;
    private const int GRID_BORDER = 6;
    private const int GRID_COLUMN_SPACING = 6;
    private const double TYPICAL_MAX_BLOCKS_RATIO = 0.3;
    private const double ZOOM_RATIO = 0.05;
    private const uint PROGRESS_DELAY_MSEC = 500;
    private const string PAINT_FILL_ACCEL = "f"; // Must be lower case
    private const string PAINT_EMPTY_ACCEL = "e"; // Must be lower case
    private const string PAINT_UNKNOWN_ACCEL = "x"; // Must be lower case

#if WITH_DEBUGGING
    public signal void debug_request (uint idx, bool is_column);
#endif

    public Model model { get; construct; }
    public Controller controller { get; construct; }
    public Cell current_cell { get; set; }
    public Cell previous_cell { get; set; }
    public Difficulty generator_grade { get; set; }
    public Difficulty game_grade { get; set; default = Difficulty.UNDEFINED;}
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
    public const string ACTION_OPTIONS = "action-options";
#if WITH_DEBUGGING
    public const string ACTION_DEBUG_ROW = "action-debug-row";
    public const string ACTION_DEBUG_COL = "action-debug-col";
#endif
    private static GLib.ActionEntry [] view_action_entries = {
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
        {ACTION_HINT, action_hint},
        {ACTION_OPTIONS, action_options}
    };

    public static Gtk.Application app;
    private ClueBox row_clue_box;
    private ClueBox column_clue_box;
    private CellGrid cell_grid;
    private ProgressIndicator progress_indicator;
    private Gtk.MenuButton menu_button;
    private CellState drawing_with_state = UNDEFINED;
    private Gtk.HeaderBar header_bar;
    private Granite.ModeSwitch mode_switch;
    private Gtk.Grid main_grid;
    private Adw.ToastOverlay toast_overlay;
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

    public View (Model _model, Controller controller) {
        Object (
            model: _model,
            controller: controller,
            resizable: true,
            title: _("Gnonograms")
        );
    }

    static construct {
        app = (Gtk.Application)(Application.get_default ());
#if WITH_DEBUGGING
warning ("WITH DEBUGGING");
        view_action_entries += ActionEntry () { name = ACTION_DEBUG_ROW, activate = action_debug_row };
        view_action_entries += ActionEntry () { name = ACTION_DEBUG_COL, activate = action_debug_col };
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
        action_accelerators.set (ACTION_PAINT_FILLED, PAINT_FILL_ACCEL);
        action_accelerators.set (ACTION_PAINT_EMPTY, PAINT_EMPTY_ACCEL);
        action_accelerators.set (ACTION_PAINT_UNKNOWN, PAINT_UNKNOWN_ACCEL);
        action_accelerators.set (ACTION_CHECK_ERRORS, "F7");
        action_accelerators.set (ACTION_RESTART, "F5");
        action_accelerators.set (ACTION_RESTART, "<Ctrl>R");
        action_accelerators.set (ACTION_HINT, "F9");
        action_accelerators.set (ACTION_HINT, "<Ctrl>H");
        action_accelerators.set (ACTION_SOLVE, "<Alt>S");
        action_accelerators.set (ACTION_OPTIONS, "F10");
        action_accelerators.set (ACTION_OPTIONS, "Menu");
#if WITH_DEBUGGING
        action_accelerators.set (ACTION_DEBUG_ROW, "<Alt>R");
        action_accelerators.set (ACTION_DEBUG_COL, "<Alt>C");
#endif

        try {
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("com/github/jeremypw/gnonograms/Application.css");
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            warning ("Error adding css provider: %s", e.message);
        }
    }

    construct {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        if (gtk_settings != null && granite_settings != null) {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            });
        }

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/com/github/jeremypw/gnonograms");

        var view_actions = new GLib.SimpleActionGroup ();
        view_actions.add_action_entries (view_action_entries, this);
        insert_action_group (ACTION_GROUP, view_actions);

        foreach (var action in action_accelerators.get_keys ()) {
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;

            app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }

        load_game_button = new HeaderButton ("document-open", ACTION_PREFIX + ACTION_OPEN, _("Load Game"));
        save_game_button = new HeaderButton ("document-save", ACTION_PREFIX + ACTION_SAVE, _("Save Game"));
        save_game_as_button = new HeaderButton ("document-save-as", ACTION_PREFIX + ACTION_SAVE_AS, _("Save Game to Different File"));
        undo_button = new HeaderButton ("edit-undo", ACTION_PREFIX + ACTION_UNDO, _("Undo Last Move"));
        redo_button = new HeaderButton ("edit-redo", ACTION_PREFIX + ACTION_REDO, _("Redo Last Move"));
        check_correct_button = new HeaderButton ("media-seek-backward", ACTION_PREFIX + ACTION_CHECK_ERRORS, _("Check for Errors"));
        restart_button = new RestartButton ("view-refresh", ACTION_PREFIX + ACTION_RESTART, _("Start again")) {
            margin_end = 12,
            margin_start = 12,
        };

        hint_button = new HeaderButton ("help-contents", ACTION_PREFIX + ACTION_HINT, _("Suggest next move"));
        auto_solve_button = new HeaderButton ("system", ACTION_PREFIX + ACTION_SOLVE, _("Solve by Computer"));
        generate_button = new HeaderButton ("list-add", ACTION_PREFIX + ACTION_GENERATING_MODE, _("Generate New Puzzle"));

        menu_button = new Gtk.MenuButton () {
            tooltip_markup = Granite.markup_accel_tooltip (
                app.get_accels_for_action (ACTION_PREFIX + ACTION_OPTIONS), _("Options")
            ),
            icon_name = "open-menu"
        };

        var app_popover = new AppPopover () {
            has_arrow = false
        };

        menu_button.set_popover (app_popover);

        app_popover.apply_settings.connect (() => {
            controller.generator_grade = app_popover.grade;
            controller.dimensions = {app_popover.columns, app_popover.rows};
            controller.game_name = app_popover.title; // Must come after changing dimensions
        });

        app_popover.show.connect (() => { /* Allow parent to set values first */
            app_popover.grade = controller.generator_grade;
            app_popover.rows = controller.dimensions.height;
            app_popover.columns = controller.dimensions.width;
            app_popover.title = controller.game_name;
        });

        // Unable to set markup on Granite.ModeSwitch so fake a Granite acellerator tooltip for now.
        mode_switch = new Granite.ModeSwitch.from_icon_name ("edit-symbolic", "head-thinking-symbolic") {
            margin_end = 12,
            margin_start = 12,
            valign = Gtk.Align.CENTER,
            primary_icon_tooltip_text = "%s\n%s".printf (_("Edit a Game"), "Ctrl + 1"),
            secondary_icon_tooltip_text = "%s\n%s".printf (_("Manually Solve"), "Ctrl + 2")
        };

        progress_indicator = new ProgressIndicator ();

        title_label = new Gtk.Label ("Gnonograms") {
            use_markup = true,
            xalign = 0.5f
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
        title_label.show ();

        grade_label = new Gtk.Label ("Easy") {
            use_markup = true,
            xalign = 0.5f
        };
        grade_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var title_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        title_grid.append (title_label);
        title_grid.append (grade_label);

        progress_stack = new Gtk.Stack ();
        progress_stack.add_named (progress_indicator, "Progress");
        progress_stack.add_named (title_grid, "Title");
        progress_stack.set_visible_child_name ("Title");

        header_bar = new Gtk.HeaderBar () {
            show_title_buttons = true,
            title_widget = progress_stack
        };
        header_bar.add_css_class ("gnonograms-header");
        header_bar.pack_start (load_game_button);
        header_bar.pack_start (save_game_button);
        header_bar.pack_start (save_game_as_button);
        header_bar.pack_start (restart_button);
        header_bar.pack_start (undo_button);
        header_bar.pack_start (redo_button);
        header_bar.pack_start (check_correct_button);
        header_bar.pack_end (menu_button);
        header_bar.pack_end (generate_button);
        header_bar.pack_end (mode_switch);
        header_bar.pack_end (auto_solve_button);
        header_bar.pack_end (hint_button);

        set_titlebar (header_bar);

        row_clue_box = new ClueBox (Gtk.Orientation.VERTICAL, this);
        column_clue_box = new ClueBox (Gtk.Orientation.HORIZONTAL, this);
        cell_grid = new CellGrid (this);

        toast_overlay = new Adw.ToastOverlay () {
            vexpand = false,
            valign = Gtk.Align.START
        };

        main_grid = new Gtk.Grid () {
            focusable = true, // Needed for key controller to work
            row_spacing = 0,
            margin_bottom = margin_end = GRID_BORDER,
            column_spacing = GRID_COLUMN_SPACING
        };
        main_grid.attach (toast_overlay, 0, 0, 1, 1); /* show temporary messages */
        main_grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues fordimensions.height*/
        main_grid.attach (column_clue_box, 1, 0, 1, 1); /* Clues for columns */
        main_grid.attach (cell_grid, 1, 1, 1, 1);

        var scroll_controller = new Gtk.EventControllerScroll (
            Gtk.EventControllerScrollFlags.VERTICAL | Gtk.EventControllerScrollFlags.DISCRETE
        );

        main_grid.add_controller (scroll_controller);
        scroll_controller.scroll.connect ((dx, dy) => {
            var modifiers = scroll_controller.
                            get_current_event_device ().
                            get_seat ().
                            get_keyboard ().
                            get_modifier_state ();

            if (modifiers == Gdk.ModifierType.CONTROL_MASK) {
                    Idle.add (() => {
                        if (dy > 0.0) {
                             action_zoom_in ();
                        } else {
                            action_zoom_out ();
                        }

                        return Source.REMOVE;
                    });

                return Gdk.EVENT_STOP;
            }

            return Gdk.EVENT_PROPAGATE;
        });

        var key_controller = new Gtk.EventControllerKey ();
        main_grid.add_controller (key_controller);

        key_controller.key_released.connect ((keyval, keycode, state) => {
            if (Gdk.keyval_to_lower (keyval) == drawing_with_key) {
                stop_painting ();
            }

            return;
        });

        child = main_grid;

        var flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
        bind_property ("restart-destructive", restart_button, "restart-destructive", BindingFlags.SYNC_CREATE);
        bind_property ("current-cell", cell_grid, "current-cell", BindingFlags.BIDIRECTIONAL);
        bind_property ("previous-cell", cell_grid, "previous-cell", BindingFlags.BIDIRECTIONAL);

        mode_switch.notify["active"].connect (() => {
            controller.game_state = mode_switch.active ? GameState.SOLVING : GameState.SETTING;
        });

        controller.notify["game-state"].connect (() => {
            if (controller.game_state != GameState.UNDEFINED) {
                update_all_labels_completeness ();
            }

            // Avoid updating header bar while generating otherwise generation will be cancelled.
            // Headerbar will update when generation finished.
            if (controller.game_state != GameState.GENERATING) {
                update_header_bar ();
            }
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
            check_correct_button.sensitive = can_go_back && controller.game_state == GameState.SOLVING;
            undo_button.sensitive = can_go_back;
            restart_destructive |= can_go_back; /* May be destructive even if no history (e.g. after automatic solve) */
        });

        notify["can-go-forward"].connect (() => {
            redo_button.sensitive = can_go_forward;
        });

        notify["current-cell"].connect (() => {
            highlight_labels (previous_cell, false);
            highlight_labels (current_cell, true);

            if (current_cell != NULL_CELL && drawing_with_state != CellState.UNDEFINED) {
                make_move_at_cell ();
            }
        });

        notify["strikeout-complete"].connect (() => {
            update_all_labels_completeness ();
        });

        controller.notify["dimensions"].connect (() => {
            calc_cell_size ();
            set_size ();
        });

        notify["cell-size"].connect (() => {
            set_size ();
        });


       cell_grid.leave.connect (() => {
            row_clue_box.unhighlight_all ();
            column_clue_box.unhighlight_all ();
        });

        cell_grid.start_drawing.connect ((button, state, double_click) => {
            if (double_click || button == Gdk.BUTTON_MIDDLE) {
                drawing_with_state = controller.game_state == SOLVING ? CellState.UNKNOWN : CellState.EMPTY;
            } else {
                if (state == SHIFT_MASK && button == Gdk.BUTTON_PRIMARY) {
                    drawing_with_state = CellState.EMPTY;
                } else {
                    drawing_with_state = button == Gdk.BUTTON_PRIMARY ? CellState.FILLED : CellState.EMPTY;
                }

            }

            make_move_at_cell ();
        });

        cell_grid.stop_drawing.connect (stop_painting);
    }

    private void calc_cell_size () {
        // Update cell-size if required to fit on screen but without changing window size unnecessarily
        // The dimensions may have increased or decreased so may need to increase or decrease cell size
        // It is assumed up to 90% of the screen area can be used
        var n_cols = controller.dimensions.width;
        var n_rows = controller.dimensions.height;

        var monitor_area = Gdk.Rectangle () {
            width = 1024,
            height = 768
        };

        Gdk.Surface? surface = get_surface ();
        if (surface != null) {
            monitor_area = Utils.get_monitor_area (surface);
        }

        var available_screen_width = monitor_area.width * 0.9 - GRID_BORDER - GRID_COLUMN_SPACING;
        var max_cell_width = available_screen_width / (n_cols * (1.3));
        var available_grid_height = (int)(surface.get_height () - header_bar.get_allocated_height () - GRID_BORDER);
        var opt_cell_height = (int)(available_grid_height / (n_rows * (1.4)));

        var available_screen_height = monitor_area.height * 0.9 - header_bar.get_allocated_height () - GRID_BORDER;
        var max_cell_height = available_screen_height / (n_rows * (1.4));

        var max_cell_size = (int)(double.min (max_cell_width, max_cell_height));
        if (max_cell_size < cell_size) {
            cell_size = max_cell_size;
        } else if (opt_cell_height > 0 && cell_size < opt_cell_height) {
            cell_size = int.min (max_cell_size, opt_cell_height);
        }
    }

    private void set_size () {
        var n_cols = controller.dimensions.width;
        var n_rows = controller.dimensions.height;
        var width = (int)((double)(n_cols * cell_size) * 1.3);
        var height = (int)((double)(n_rows * cell_size) * 1.4);

        set_default_size (
            width + GRID_BORDER + GRID_COLUMN_SPACING,
            height + header_bar.get_allocated_height () + GRID_BORDER
        );
        main_grid.set_size_request (
            width,
            height
        );

        queue_draw ();
    }

    public string[] get_clues (bool is_column) {
        var label_box = is_column ? column_clue_box : row_clue_box;
        return label_box.get_clue_texts ();
    }

    public void update_clues_from_string_array (string[] clues, bool is_column) {
        var clue_box = is_column ? column_clue_box : row_clue_box;
        var lim = is_column ? controller.dimensions.width : controller.dimensions.height;

        for (int i = 0; i < lim; i++) {
            clue_box.update_clue_text (i, clues[i]);
        }
    }

    public void update_clues_from_solution () {
        for (int r = 0; r < controller.dimensions.height; r++) {
            row_clue_box.update_clue_text (r, model.get_label_text_from_solution (r, false));
        }

        for (int c = 0; c < controller.dimensions.width; c++) {
            column_clue_box.update_clue_text (c, model.get_label_text_from_solution (c, true));
        }

        update_all_labels_completeness ();
    }

    public void make_move (Move m) {
        if (!m.is_null ()) {
            update_current_and_model (m.cell.state, m.cell);
        }
    }

    public void send_notification (string text) {
        toast_overlay.add_toast (new Adw.Toast (text));
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
        mode_switch.active = controller.game_state != GameState.SETTING;

        switch (controller.game_state) {
            case GameState.SETTING:
                set_buttons_sensitive (true);
                break;
            case GameState.SOLVING:
                set_buttons_sensitive (true);

                break;
            case GameState.GENERATING:
                set_buttons_sensitive (false);

                break;
            default:
                break;
        }
    }

    public void update_title () {
        title_label.label = game_name;
        title_label.tooltip_text = controller.current_game_path;
        grade_label.label = game_grade.to_string ();
    }

    private void set_buttons_sensitive (bool sensitive) {
        generate_button.sensitive = controller.game_state != GameState.GENERATING;
        mode_switch.sensitive = sensitive;
        load_game_button.sensitive = sensitive;
        save_game_button.sensitive = sensitive;
        save_game_as_button.sensitive = sensitive;
        restart_destructive = sensitive && !model.is_blank (controller.game_state);
        undo_button.sensitive = sensitive && can_go_back;
        redo_button.sensitive = sensitive && can_go_forward;
        check_correct_button.sensitive = sensitive && controller.game_state == GameState.SOLVING && can_go_back;
        hint_button.sensitive = sensitive && controller.game_state == GameState.SOLVING;
        auto_solve_button.sensitive = sensitive;
    }

    private void highlight_labels (Cell c, bool is_highlight) {
        /* If c is NULL_CELL then will unhighlight all labels */
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void update_all_labels_completeness () {
        for (int r = 0; r < controller.dimensions.height; r++) {
            update_clue_complete (r, false);
        }

        for (int c = 0; c < controller.dimensions.width; c++) {
            update_clue_complete (c, true);
        }
    }

    private void update_clue_complete (uint idx, bool is_col) {
        var lbox = is_col ? column_clue_box : row_clue_box;

        if (controller.game_state == GameState.SOLVING && strikeout_complete) {
            var blocks = Gee.List.empty<Block> ();
            blocks = model.get_complete_blocks_from_working (idx, is_col);
            lbox.update_clue_complete (idx, blocks);
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
            row_clue_box.update_clue_text (row, model.get_label_text_from_solution (row, false));
            column_clue_box.update_clue_text (col, model.get_label_text_from_solution (col, true));
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
        progress_timeout_id = Timeout.add_full (Priority.HIGH_IDLE, PROGRESS_DELAY_MSEC, () => {
            progress_indicator.cancellable = cancellable;
            progress_stack.set_visible_child_name ("Progress");
            progress_timeout_id = 0;
            return false;
        });
    }

    private void stop_painting () {
        drawing_with_state = CellState.UNDEFINED;
        drawing_with_key = 0;
    }

    /** Action callbacks **/
    private void action_restart () {
        controller.restart ();
        if (controller.game_state == GameState.SETTING) {
            game_grade = Difficulty.UNDEFINED;
        }
    }

    private void action_solve () {
        controller.computer_solve ();
    }

    private void action_hint () {
        controller.hint ();
    }

    private void action_options () {
        menu_button.activate ();
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
        controller.save_game ();
    }

    private void action_save_as () {
        controller.save_game_as ();
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
        if (current_cell == NULL_CELL) {
            return;
        }

        Cell target = {current_cell.row + row_delta,
                       current_cell.col + col_delta,
                       CellState.UNDEFINED
                      };

        if (target.row >= controller.dimensions.height || target.col >= controller.dimensions.width) {
            return;
        }

        update_current_cell (target);
    }

    private void action_setting_mode () {
        controller.game_state = GameState.SETTING;
    }
    private void action_solving_mode () {
        controller.game_state = GameState.SOLVING;
    }
    private void action_generating_mode () {
        controller.game_state = GameState.GENERATING;
    }

    private void action_paint_filled () {
        paint_cell_state (CellState.FILLED);
        drawing_with_key = Gdk.keyval_from_name (PAINT_FILL_ACCEL);
    }
    private void action_paint_empty () {
        paint_cell_state (CellState.EMPTY);
        drawing_with_key = Gdk.keyval_from_name (PAINT_EMPTY_ACCEL);
    }
    private void action_paint_unknown () {
        paint_cell_state (CellState.UNKNOWN);
        drawing_with_key = Gdk.keyval_from_name (PAINT_UNKNOWN_ACCEL);
    }
    private void paint_cell_state (CellState cs) {
        if (cs == CellState.UNKNOWN && controller.game_state != GameState.SOLVING) {
            return;
        }

        drawing_with_state = cs;

        make_move_at_cell ();
    }
}
