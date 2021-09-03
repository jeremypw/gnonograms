/* View class for gnonograms - displays user interface
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

/*** The View class manages the header, clue label widgets and the drawing widget under instruction
   * from the controller. It signals user interaction to the controller.
***/
public class Gnonograms.View : Hdy.ApplicationWindow {

/**PUBLIC**/
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
    public signal void debug_request (uint idx, bool is_column);
    public signal void changed_cell (Cell cell, CellState previous_state);

    public Model model {private get; construct; }
    public unowned Controller controller { get; construct; }
    public Dimensions dimensions { get; set; }
    public Difficulty generator_grade { get; set; }
    public GameState game_state { get; set; }
    public bool strikeout_complete { get; set; }
    public string game_name { get { return controller.game_name; } }
    public bool readonly { get; set; default = false;}
    public Difficulty game_grade { get; set; default = Difficulty.UNDEFINED;}
    public double fontheight { get; set; }
    public bool can_go_back { get; set; }
    public bool can_go_forward { get; set; }
    public bool restart_destructive { get; set; default = false;}
    public Cell current_cell { get; set; }
    public Cell previous_cell { get; set; }

    private const uint PROGRESS_DELAY_MSEC = 500;

    private const GLib.ActionEntry [] VIEW_ACTION_ENTRIES = {
        {"undo", action_undo},
        {"redo", action_redo},
        {"zoom", action_zoom, "i"},
        {"move-cursor", action_move_cursor, "(ii)"},
        {"set-mode", action_set_mode, "u"},
        {"open", action_open},
        {"save", action_save},
        {"save-as", action_save_as},
        {"paint-cell", action_paint_cell, "u"},
        {"check-errors", action_check_errors},
        {"restart", action_restart},
        {"solve", action_solve},
        {"hint", action_hint},
        {"debug-row", action_debug_row},
        {"debug-col", action_debug_col}
    };

    private LabelBox row_clue_box;
    private LabelBox column_clue_box;
    private CellGrid cell_grid;
    private Hdy.HeaderBar header_bar;
    private AppMenu app_menu;
    private Gtk.Grid main_grid;
    private Gtk.Overlay overlay;
    private ProgressIndicator progress_indicator;
    private Gtk.Stack progress_stack;
    private Gtk.Label title_label;
    private Granite.Widgets.Toast toast;
    private ViewModeButton mode_switch;
    private Gtk.Button load_game_button;
    private Gtk.Button save_game_button;
    private Gtk.Button save_game_as_button;
    private Gtk.Button undo_button;
    private Gtk.Button redo_button;
    private Gtk.Button check_correct_button;
    private Gtk.Button hint_button;
    private Gtk.Button auto_solve_button;
    private Gtk.Button restart_button;
    private CellState drawing_with_state;
    private uint drawing_with_key;
    private uint rows {get {return dimensions.rows ();}}
    private uint cols {get {return dimensions.cols ();}}
    private bool is_solving {get {return game_state == GameState.SOLVING;}}

    /* ----------------------------------------- */
    public View (Model _model, Controller controller) {
        Object (
            model: _model,
            controller: controller
        );
    }

    static construct {
        Hdy.init ();
    }

    construct {
        var view_actions = new GLib.SimpleActionGroup ();
        view_actions.add_action_entries (VIEW_ACTION_ENTRIES, this);
        view_actions.add_action_entries (VIEW_ACTION_ENTRIES, this);
        insert_action_group ("view", view_actions);

        var application = get_app ();
        application.set_accels_for_action ("view.undo", {"<Ctrl>Z"});
        application.set_accels_for_action ("view.redo", {"<Ctrl><Shift>Z"});
        application.set_accels_for_action ("view.move-cursor((-1, 0))", {"Up"});
        application.set_accels_for_action ("view.move-cursor((1, 0))", {"Down"});
        application.set_accels_for_action ("view.move-cursor((0, -1))", {"Left"});
        application.set_accels_for_action ("view.move-cursor((0, 1))", {"Right"});
        application.set_accels_for_action ("view.zoom(int32 1)", {"<Ctrl>plus", "<Ctrl>equal", "<Ctrl>KP_Add"});
        application.set_accels_for_action ("view.zoom(int32 -1)", {"<Ctrl>minus", "<Ctrl>KP_Subtract"});
        application.set_accels_for_action ("view.set-mode(uint32 %u)"
                                           .printf (GameState.SETTING), {"<Ctrl>1"});

        application.set_accels_for_action ("view.set-mode(uint32 %u)"
                                           .printf (GameState.SOLVING), {"<Ctrl>2"});

        application.set_accels_for_action ("view.set-mode(uint32 %u)"
                                           .printf (GameState.GENERATING), {"<Ctrl>3", "<Ctrl>N"});

        application.set_accels_for_action ("view.open", {"<Ctrl>O"});
        application.set_accels_for_action ("view.save", {"<Ctrl>S"});
        application.set_accels_for_action ("view.save-as", {"<Ctrl><Shift>S"});
        application.set_accels_for_action ("view.paint-cell(uint32 %u)"
                                           .printf (CellState.FILLED), {"F"});

        application.set_accels_for_action ("view.paint-cell(uint32 %u)"
                                           .printf (CellState.EMPTY), {"E"});

        application.set_accels_for_action ("view.paint-cell(uint32 %u)"
                                           .printf (CellState.UNKNOWN), {"X"});

        application.set_accels_for_action ("view.check-errors", {"F7", "less", "comma"});
        application.set_accels_for_action ("view.restart", {"F5", "<Ctrl>R"});
        application.set_accels_for_action ("view.hint", {"F9", "<Ctrl>H"});
        application.set_accels_for_action ("view.debug-row", {"<Alt>R"});
        application.set_accels_for_action ("view.debug-col", {"<Alt>C"});

        resizable = true;
        drawing_with_state = CellState.UNDEFINED;

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/gnonograms/icons");

        header_bar = new Hdy.HeaderBar ();
        header_bar.set_has_subtitle (false);
        header_bar.set_show_close_button (true);

        load_game_button = new HeaderButton ("document-open",
                                             _("Load a Game from File"));

        save_game_button = new HeaderButton ("document-save", _("Save Game"));

        save_game_as_button = new HeaderButton ("document-save-as",
                                                _("Save Game to Different File"));

        undo_button = new HeaderButton ("edit-undo", _("Undo Last Move"));
        undo_button.sensitive = false;

        redo_button = new HeaderButton ("edit-redo", _("Redo Last Move"));
        redo_button.sensitive = false;

        check_correct_button = new HeaderButton ("media-seek-backward",
                                                 _("Go Back to Last Correct Position"));
        check_correct_button.sensitive = false;

        restart_button = new RestartButton ("view-refresh", ""); /* private class - see below */

        hint_button = new HeaderButton ("help-contents", _("Suggest next move"));
        hint_button.sensitive = false;

        auto_solve_button = new HeaderButton ("system", _("Solve by Computer"));
        auto_solve_button.sensitive = false;

        app_menu = new AppMenu (controller);
        mode_switch = new ViewModeButton ();
        mode_switch.margin_top = 6;
        mode_switch.margin_bottom = 6;
        mode_switch.get_style_context ().add_class ("mode-switch");

        progress_indicator = new ProgressIndicator ();
        // progress_indicator.get_style_context ().add_class ("progress");

        title_label = new Gtk.Label ("Gnonograms");
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        title_label.show ();

        progress_stack = new Gtk.Stack ();
        progress_stack.add_named (progress_indicator, "Progress");
        progress_stack.add_named (title_label, "Title");
        progress_stack.set_visible_child_name ("Title");
        // progress_stack.set_size_request (150, -1);

        header_bar.pack_start (load_game_button);
        header_bar.pack_start (save_game_button);
        header_bar.pack_start (save_game_as_button);
        header_bar.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_start (restart_button);
        header_bar.pack_start (undo_button);
        header_bar.pack_start (redo_button);
        header_bar.pack_start (check_correct_button);

        header_bar.pack_end (app_menu);
        header_bar.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_end (mode_switch);
        header_bar.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_end (auto_solve_button);
        header_bar.pack_end (hint_button);
        header_bar.set_custom_title (progress_stack);

        overlay = new Gtk.Overlay () {
            expand = true
        };

        toast = new Granite.Widgets.Toast ("");

        toast.set_default_action (null);
        toast.halign = Gtk.Align.START;
        toast.valign = Gtk.Align.START;
        overlay.add_overlay (toast);

        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL);

        cell_grid = new CellGrid (model);

        main_grid = new Gtk.Grid ();
        main_grid.attach (cell_grid, 1, 1, 1, 1);

        main_grid.row_spacing = 0;
        main_grid.column_spacing = GRID_COLUMN_SPACING;
        main_grid.border_width = GRID_BORDER;
        main_grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues for rows */
        main_grid.attach (column_clue_box, 1, 0, 1, 1); /* Clues for columns */

        var ev = new Gtk.EventBox ();
        ev.add_events (Gdk.EventMask.SCROLL_MASK);
        ev.scroll_event.connect (on_grid_scroll_event);

        ev.add (main_grid);
        var sw = new Gtk.ScrolledWindow (null, null);
        sw.add (ev);

        overlay.add (sw);

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        grid.add (header_bar);
        grid.add (overlay);

        add (grid);

        /* Connect signal handlers */
        cell_grid.leave_notify_event.connect (on_grid_leave);
        cell_grid.button_press_event.connect (on_grid_button_press);
        cell_grid.button_release_event.connect (stop_painting);
        key_release_event.connect (on_key_release_event);

        /* Set actions */
        undo_button.set_action_name ("view.undo");
        redo_button.set_action_name ("view.redo");
        load_game_button.set_action_name ("view.open");
        save_game_button.set_action_name ("view.save");
        save_game_as_button.set_action_name ("view.save-as");
        check_correct_button.set_action_name ("view.check-errors");
        restart_button.set_action_name ("view.restart");
        hint_button.set_action_name ("view.hint");
        auto_solve_button.set_action_name ("view.solve");

        /* Bind some properties */
        var flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
        bind_property ("restart-destructive", restart_button, "restart-destructive", BindingFlags.SYNC_CREATE) ;
        bind_property ("dimensions", app_menu, "dimensions", flags);
        bind_property ("generator-grade", app_menu, "grade", flags);
        controller.bind_property ("game-name", app_menu, "title", flags);
        bind_property ("strikeout-complete", app_menu, "strikeout-complete", flags);
        bind_property ("game-state", mode_switch, "mode", flags);
        bind_property ("current-cell", cell_grid, "current-cell", BindingFlags.BIDIRECTIONAL);
        bind_property ("previous-cell", cell_grid, "previous-cell", BindingFlags.BIDIRECTIONAL);
        bind_property ("fontheight", row_clue_box, "fontheight");
        bind_property ("fontheight", column_clue_box, "fontheight");
        bind_property ("dimensions", row_clue_box, "dimensions");
        bind_property ("dimensions", column_clue_box, "dimensions");


        /* Monitor certain bound properties */
        notify["game-state"].connect (() => {
            if (game_state != GameState.UNDEFINED) {
                update_all_labels_completeness ();
            }
        });

        notify["dimensions"].connect (() => {
            fontheight = get_default_fontheight_from_dimensions ();
            set_window_size ();
        });

        notify["generator-grade"].connect (() => {
            mode_switch.grade = generator_grade;
        });

        controller.notify["game-name"].connect (() => {
            title_label.label = game_name;
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

        notify["fontheight"].connect (() => {
            fontheight = fontheight.clamp (MINFONTSIZE, MAXFONTSIZE);
            set_window_size ();
        });

        realize.connect (set_window_size);
    }

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

    /*** PRIVATE ***/
    private double get_default_fontheight_from_dimensions () {
        var monitor_area = Gdk.Rectangle () {width = 1024, height = 768};

        Gdk.Window? window = get_window ();
        if (window != null) {
            monitor_area = Utils.get_monitor_area (screen, window);
        }

         /* Cell dimensions approx 2.0 * font height
         * Make allowance for unusable monitor height - approx 10%;
         * These equations are related to the inverse of those used in labelbox to calculate its dimensions
         */

        double max_h = (monitor_area.height * USABLE_MONITOR_HEIGHT - header_bar.get_allocated_height () -
                       2 * GRID_BORDER) / (rows * (1.0 + TYPICAL_MAX_BLOCKS_RATIO * FONT_ASPECT_RATIO) * 2.0);

        double max_w = (monitor_area.width * USABLE_MONITOR_WIDTH - 2 * GRID_BORDER -
                       GRID_COLUMN_SPACING) / (cols * (1.0 + TYPICAL_MAX_BLOCKS_RATIO / FONT_ASPECT_RATIO) * 2.0);

        return double.min (max_h, max_w);
    }

    private void set_window_size () {
        Gdk.Window? window = get_window ();

        if (window == null) {
            return;
        }

        var monitor_area = Utils.get_monitor_area (screen, window);
        var usable_width = (int)(monitor_area.width * USABLE_MONITOR_WIDTH);
        var w = int.min (usable_width,
                         row_clue_box.min_width + column_clue_box.min_width + 2 * GRID_BORDER + GRID_COLUMN_SPACING);

        var usable_height = (int)(monitor_area.height * USABLE_MONITOR_HEIGHT);

        var h = int.min (usable_height,
                         row_clue_box.min_height + column_clue_box.min_height +
                         2 * GRID_BORDER + header_bar.get_allocated_height ());

        var hints = Gdk.Geometry ();
        hints.min_width = w;
        hints.min_height = h;

        set_geometry_hints (overlay, hints, Gdk.WindowHints.MIN_SIZE);
        resize (w, h);
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

    private void set_buttons_sensitive (bool sensitive) {
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
                    fontheight -= 1.0;
                    break;

                case Gdk.ScrollDirection.DOWN:
                    fontheight += 1.0;
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
    }

    private void action_solve () {
        solve_this_request ();
    }

    private void action_hint () {
        hint_request ();
    }

    private void action_debug_row () {
        debug_request (current_cell.row, false);
    }

    private void action_debug_col () {
        debug_request (current_cell.col, true);
    }

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

    private void action_zoom (SimpleAction action, Variant? param) {
        fontheight += param.get_int32 ();
    }

    private void action_check_errors () {
        if (rewind_request () == 0) {
            send_notification (_("No errors"));
        }
    }

    private void action_move_cursor (SimpleAction action, Variant? param) {
        int dr, dc;
        param.get_child (0, "i", out dr);
        param.get_child (1, "i", out dc);

        if (current_cell == NULL_CELL) {
            return;
        }

        Cell target = {current_cell.row + dr,
                       current_cell.col + dc,
                       CellState.UNDEFINED
                      };

        if (target.row >= rows || target.col >= cols) {
            return;
        }

        update_current_cell (target);
    }

    private void action_set_mode (SimpleAction action, Variant? param) {
        game_state = (GameState)(param.get_uint32 ());
    }

    private void action_paint_cell (SimpleAction action, Variant? param) {
        var cs = (CellState)(param.get_uint32 ());
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
