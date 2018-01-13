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

namespace Gnonograms {
/*** The View class manages the header, clue label widgets and the drawing widget under instruction
   * from the controller. It signals user interaction to the controller.
***/
public class View : Gtk.ApplicationWindow {
/**PUBLIC**/
    public signal void random_game_request ();
    public signal uint check_errors_request ();
    public signal void rewind_request ();
    public signal bool next_move_request ();
    public signal bool previous_move_request ();
    public signal void save_game_request ();
    public signal void save_game_as_request ();
    public signal void open_game_request ();
    public signal void solve_this_request ();
    public signal void restart_request ();
    public signal void resized (Dimensions dim);
    public signal void moved (Cell cell);
    public signal void game_state_changed (GameState gs);

    public Model model { get; construct; }

    private string? _game_name = null;
    public string game_name {
        get {
            if (_game_name == null || _game_name == "") {
                return Gnonograms.UNTITLED_NAME;
            } else {
                return _game_name;
            }
        }

        set {
            _game_name = value;
            if (value != Gnonograms.UNTITLED_NAME) {
                app_menu.title = value;
            }
            update_header_bar ();
        }
    }

    private Dimensions _dimensions;
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            if (value != _dimensions) {
                _dimensions = value;
                row_clue_box.dimensions = dimensions;
                column_clue_box.dimensions = dimensions;
                fontheight = get_default_fontheight_from_dimensions ();
                app_menu.row_val = value.height;
                app_menu.column_val = value.width;
                resized (value); /* Controller will queue draw after resizing model */
            }
        }
    }

    private Difficulty _game_grade = Difficulty.UNDEFINED;
    public Difficulty game_grade { // Difficulty of game actually loaded
        get {
            return _game_grade;
        }

        set {
            _game_grade = value;
            update_header_bar ();
        }
    }
    private Difficulty _generator_grade;
    public Difficulty generator_grade { // Grade setting

        get {
            return _generator_grade;
        }

        set {
            _generator_grade = value;
            app_menu.grade_val = (uint)_generator_grade;
        }
    }
    private bool _readonly;
    public bool readonly {

        get {
            return _readonly;
        }

        set {
            _readonly = value;
            update_header_bar ();
        }
    }

    public uint rows {
        get {
            return dimensions.rows ();
        }
    }

    public uint cols {
        get {
            return dimensions.cols ();
        }
    }

    private double _fontheight;
    public double fontheight {
        get {
            return _fontheight;
        }


        set {
            if (value < MINFONTSIZE || value > MAXFONTSIZE) {
                return;
            }

            _fontheight = value;
            row_clue_box.fontheight = _fontheight;
            column_clue_box.fontheight = _fontheight;

            /* Avoid window resizing as clues change */
            /* Typical longest row clue width approx cols * 0.45 char) */
            row_clue_box.set_size_request((int)(cols * 0.45 * fontheight), -1);
            /* Typical longest col clue width approx rows * 0.55) */
            column_clue_box.set_size_request(-1, (int)(rows * 0.55 * fontheight));
        }
    }

    private GameState _game_state = GameState.UNDEFINED;
    public GameState game_state {
        get {
            return _game_state;
        }

        set {
            if (_game_state != value) {
                _game_state = value;
                mode_switch.mode = value;
                cell_grid.game_state = value;

                update_header_bar ();
            }
        }
    }

    public bool can_go_back {
        set {
            check_correct_button.sensitive = value && is_solving;
            undo_button.sensitive = value;
        }
    }

    public bool model_matches_labels {
        get {
            if (model == null || row_clue_box == null || column_clue_box == null) {
                return false;
            }

            int index = 0;
            foreach (string clue in get_row_clues ()) {
                if (clue != model.get_label_text_from_working (index, false)) {
                    return false;
                }

                index++;
            }

            index = 0;
            foreach (string clue in get_col_clues ()) {
                if (clue != model.get_label_text_from_working (index, true)) {
                    return false;
                }

                index++;
            }

            return true;
        }
    }

    public View (Model _model) {
        Object (
            model: _model
        );
    }

    construct {
        resizable = false;
        drawing_with_state = CellState.UNDEFINED;

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/gnonograms/icons");

        header_bar = new Gtk.HeaderBar ();
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        title = _("Gnonograms for Elementary");

        load_game_button = new Gtk.Button ();
        var img = new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
        load_game_button.image = img;
        load_game_button.tooltip_text = _("Load a Game from File");

        save_game_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.LARGE_TOOLBAR);
        save_game_button.image = img;
        save_game_button.tooltip_text = _("Save Game");

        save_game_as_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR);
        save_game_as_button.image = img;
        save_game_as_button.tooltip_text = _("Save Game to Different File");

        undo_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("edit-undo", Gtk.IconSize.LARGE_TOOLBAR);
        undo_button.image = img;
        undo_button.tooltip_text = _("Undo Last Move");
        undo_button.sensitive = false;

        check_correct_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("media-seek-backward", Gtk.IconSize.LARGE_TOOLBAR);
        check_correct_button.image = img;
        check_correct_button.tooltip_text = _("Go Back to Last Correct Position");
        check_correct_button.sensitive = false;

        restart_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("view-refresh", Gtk.IconSize.LARGE_TOOLBAR);
        restart_button.image = img;
        restart_button.sensitive = true;

        auto_solve_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("system-run", Gtk.IconSize.LARGE_TOOLBAR);
        auto_solve_button.image = img;
        auto_solve_button.tooltip_text = _("Solve by Computer");
        auto_solve_button.sensitive = true;

        app_menu = new AppMenu ();
        mode_switch = new ViewModeButton ();

        progress_indicator = new Gnonograms.Progress_indicator ();

        header_bar.pack_start (load_game_button);
        header_bar.pack_start (save_game_button);
        header_bar.pack_start (save_game_as_button);
        header_bar.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_start (restart_button);
        header_bar.pack_start (undo_button);
        header_bar.pack_start (check_correct_button);
        header_bar.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        header_bar.pack_start (auto_solve_button);


        header_bar.pack_end (app_menu);
        header_bar.pack_end (mode_switch);

        set_titlebar (header_bar);

        overlay = new Gtk.Overlay ();
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
        cell_grid.cursor_moved.connect (on_grid_cursor_moved);
        cell_grid.leave_notify_event.connect (on_grid_leave);
        cell_grid.button_press_event.connect (on_grid_button_press);
        cell_grid.button_release_event.connect (on_grid_button_release);
        cell_grid.scroll_event.connect (on_scroll_event);

        main_grid.row_spacing = 6;
        main_grid.column_spacing = 6;
        main_grid.border_width = 6;
        main_grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues for rows */
        main_grid.attach (column_clue_box, 1, 0, 1, 1); /* Clues for columns */
        overlay.add (main_grid);
        add (overlay);

        /* Connect signal handlers */
        mode_switch.mode_changed.connect (on_mode_switch_changed);
        key_press_event.connect (on_key_press_event);
        key_release_event.connect (on_key_release_event);

        app_menu.apply.connect (on_app_menu_apply);

        load_game_button.clicked.connect (on_load_game_button_clicked);
        save_game_button.clicked.connect (on_save_game_button_clicked);
        save_game_as_button.clicked.connect (on_save_game_as_button_clicked);
        check_correct_button.clicked.connect (on_check_button_pressed);
        undo_button.clicked.connect (on_undo_button_pressed);
        restart_button.clicked.connect (on_restart_button_pressed);
        auto_solve_button.clicked.connect (on_auto_solve_button_pressed);

        dimensions = model.dimensions;
        generator_grade = Difficulty.MODERATE;

        show_all ();
    }

    public void blank_labels () {
        row_clue_box.blank_labels ();
        column_clue_box.blank_labels ();
    }

    public string[] get_row_clues () {
        return row_clue_box.get_clues ();
    }

    public string[] get_col_clues () {
        return column_clue_box.get_clues ();
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
    }

    public void make_move (Move m) {
        move_cursor_to (m.cell);
        mark_cell (m.cell);

        queue_draw ();
    }

    public void send_notification (string text) {
        toast.title = text;
        toast.send_notification ();
        Timeout.add_seconds (NOTIFICATION_TIMEOUT_SEC, () => {
            toast.reveal_child = false;
            return false;
        });
    }

    public void show_working (Cancellable cancellable, string text = "") {
        cell_grid.frozen = true; // Do not show model updates
        progress_indicator.text = text;
        schedule_show_progress (cancellable);
    }

    public void hide_progress () {
        cell_grid.frozen = false; // Show model updates again

        if (progress_timeout_id > 0) {
            Source.remove (progress_timeout_id);
            progress_timeout_id = 0;
        } else {
            header_bar.set_custom_title (null);
        }
    }

    /**PRIVATE**/
    private const uint NOTIFICATION_TIMEOUT_SEC = 10;
    private const uint PROGRESS_DELAY_MSEC = 500;

    private Gnonograms.LabelBox row_clue_box;
    private Gnonograms.LabelBox column_clue_box;
    private CellGrid cell_grid;
    private Gtk.HeaderBar header_bar;
    private AppMenu app_menu;
    private Gtk.Grid main_grid;
    private Gtk.Overlay overlay;
    private Gnonograms.Progress_indicator progress_indicator;
    private Granite.Widgets.Toast toast;
    private ViewModeButton mode_switch;
    private Gtk.Button load_game_button;
    private Gtk.Button save_game_button;
    private Gtk.Button save_game_as_button;
    private Gtk.Button undo_button;
    private Gtk.Button check_correct_button;
    private Gtk.Button auto_solve_button;
    private Gtk.Button restart_button;

    private bool control_pressed = false;
    private bool other_mod_pressed = false;
    private bool shift_pressed = false;
    private bool only_control_pressed = false;
    /* ----------------------------------------- */

    private CellState drawing_with_state;

    private bool is_solving {
        get {
            return game_state == GameState.SOLVING;
        }
    }

    private unowned Cell current_cell {
        get {
            return cell_grid.current_cell;
        }
        set {
            cell_grid.current_cell = value;
        }
    }

    private bool mods {
        get {
            return control_pressed || other_mod_pressed;
        }
    }

    private double get_default_fontheight_from_dimensions () {
        double max_h, max_w;
        Gdk.Rectangle rect;

        if (get_window () == null) {
            return DEFAULT_FONT_HEIGHT;
        }

#if HAVE_GDK_3_22
        var display = Gdk.Display.get_default();
        var monitor = display.get_monitor_at_window (get_window ());
        monitor.get_geometry (out rect);
#else
        var monitor = screen.get_monitor_at_window (get_window ());
        screen.get_monitor_geometry (monitor, out rect);
#endif
        /* Window height excluding header is approx 1.33 * grid height
         * Window width approx 1.25 * grid width.
         * Cell dimensions approx 2.0 * font height
         * Make allowance for unusable monitor height -approx 64px;
         */
        max_h = (double)(rect.height - 64) / 1.33 / (double)rows / 2.0;
        max_w = (double)(rect.width) / 1.25 / (double)cols / 2.0;

        return double.min (max_h, max_w);
    }

    private void update_header_bar () {
        if (game_state == GameState.SETTING) {
            header_bar.title = _("Drawing %s").printf (game_name);
            header_bar.subtitle = readonly ? _("Read Only - Save to a different file") : _("Save will Overwrite");
            restart_button.tooltip_text = _("Clear canvas");
            set_buttons_sensitive (true);
        } else if (game_state == GameState.SOLVING) {
            header_bar.title = _("Solving %s").printf (game_name);
            header_bar.subtitle = game_grade.to_string ();
            restart_button.tooltip_text = _("Restart solving");
            set_buttons_sensitive (true);
        } else {
            set_buttons_sensitive (false);
        }

        mode_switch.grade = generator_grade;
    }

    private void set_buttons_sensitive (bool sensitive) {
        mode_switch.sensitive = sensitive;
        load_game_button.sensitive = sensitive;
        save_game_button.sensitive = sensitive;
        save_game_as_button.sensitive = sensitive;
        undo_button.sensitive = sensitive;
        check_correct_button.sensitive = sensitive;
        auto_solve_button.sensitive = sensitive;
        restart_button.sensitive = sensitive;
    }

    private void update_solution_labels_for_cell (Cell cell) {
        if (cell == NULL_CELL) {
            return;
        }

        row_clue_box.update_label_text (cell.row, model.get_label_text_from_solution (cell.row, false));
        column_clue_box.update_label_text (cell.col, model.get_label_text_from_solution (cell.col, true));
    }

    private void highlight_labels (Cell c, bool is_highlight) {
        /* If c is NULL_CELL then will unhighlight all labels */
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void make_move_at_cell (CellState state = drawing_with_state, Cell target = current_cell) {
        if (target == NULL_CELL) {
            return;
        }

        if (state != CellState.UNDEFINED) {
            Cell cell = target.clone ();
            cell.state = state;
            moved (cell);
            mark_cell (cell);
            cell_grid.highlight_cell (cell, true);
        }
    }

    private void move_cursor_to (Cell to, Cell from = current_cell) {
        highlight_labels  (from, false);
        highlight_labels (to, true);
        current_cell = to;
    }

    private void mark_cell (Cell cell) {
        if (!is_solving && cell.state != CellState.UNDEFINED) {
            update_solution_labels_for_cell (cell);
        }
    }

    private void handle_arrow_keys (string keyname) {
        int r = 0; int c = 0;
        switch (keyname) {
            case "UP":
                    r = -1;
                    break;
            case "DOWN":
                    r = 1;
                    break;
            case "LEFT":
                    c = -1;
                    break;
            case "RIGHT":
                    c = 1;
                    break;

            default:
                    return;
        }

        cell_grid.move_cursor_relative (r, c);
    }

    private void handle_pen_keys (string keyname) {
        if (mods) {
            return;
        }

        switch (keyname) {
            case "F":
                drawing_with_state = CellState.FILLED;
                break;

            case "E":
                drawing_with_state = CellState.EMPTY;
                break;

            case "X":
                if (is_solving) {
                    drawing_with_state = CellState.UNKNOWN;
                    break;
                } else {
                    return;
                }

            default:
                    return;
        }

        make_move_at_cell ();
    }

    private uint progress_timeout_id = 0;
    private void schedule_show_progress (Cancellable cancellable) {
        progress_timeout_id = Timeout.add_full (Priority.HIGH_IDLE, PROGRESS_DELAY_MSEC, () => {
            progress_indicator.cancellable = cancellable;
            header_bar.set_custom_title (progress_indicator);
            this.queue_draw ();
            progress_timeout_id = 0;
            return false;
        });
    }

    /*** Signal handlers ***/
    private void on_grid_cursor_moved (Cell from, Cell to) {
        highlight_labels (from, false);
        highlight_labels (to, true);
        current_cell = to;
        make_move_at_cell ();
    }

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

    private bool on_grid_button_release () {
        drawing_with_state = CellState.UNDEFINED;
        return true;
    }

    /** With Control pressed, zoom using the fontsize.  Else, if button is down (drawing)
      * draw a straight line in the scroll direction.
    **/
    private bool on_scroll_event (Gdk.EventScroll event) {
        set_mods (event.state);

        if (control_pressed) {

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

        } else if (drawing_with_state != CellState.UNDEFINED) {

            switch (event.direction) {
                case Gdk.ScrollDirection.UP:
                    handle_arrow_keys ("UP");
                    break;

                case Gdk.ScrollDirection.DOWN:
                    handle_arrow_keys ("DOWN");
                    break;

                case Gdk.ScrollDirection.LEFT:
                    handle_arrow_keys ("LEFT");
                    break;

                case Gdk.ScrollDirection.RIGHT:
                    handle_arrow_keys ("RIGHT");
                    break;

                default:
                    return false;
            }

            /* Cause mouse pointer to follow current cell */
            int window_x, window_y;
            double x = (current_cell.col + 0.5) * cell_grid.cell_width;
            double y = (current_cell.row + 0.5) * cell_grid.cell_height;

            cell_grid.get_window ().get_root_coords ((int)x, (int)y, out window_x, out window_y);
            event.device.warp (screen, window_x, window_y);

            return true;
        }

        return false;
    }

    private bool on_key_press_event (Gdk.EventKey event) {
        /* TODO (if necessary) ignore key autorepeat */
        if (event.is_modifier == 1) {
            return true;
        }

        set_mods (event.state);
        var name = (Gdk.keyval_name (event.keyval)).up();

        switch (name) {
            case "UP":
            case "DOWN":
            case "LEFT":
            case "RIGHT":
                handle_arrow_keys (name);
                break;

            case "F":
            case "E":
            case "X":
                handle_pen_keys (name);
                break;

            case "1":
            case "2":
                if (only_control_pressed) {
                    game_state = name == "1" ? GameState.SETTING : GameState.SOLVING;
                }

                break;

            case "MINUS":
            case "KP_SUBTRACT":
            case "EQUAL":
            case "PLUS":
            case "KP_ADD":
                if (only_control_pressed) {
                    if (name == "MINUS" || name == "KP_SUBTRACT") {
                        fontheight -= 1.0;
                    } else {
                        fontheight += 1.0;
                    }
                }

                break;

            case "R":
                if (only_control_pressed) {
                    random_game_request ();
                }

                break;

            case "S":
                if (only_control_pressed) {
                    if (shift_pressed) {
                        save_game_as_request ();
                    } else {
                        save_game_request ();
                    }
                }

                break;

            case "O":
                if (only_control_pressed) {
                    open_game_request ();
                }

                break;

            default:
                return false;
        }
        return true;
    }

    private bool on_key_release_event (Gdk.EventKey event) {
        var name = (Gdk.keyval_name (event.keyval)).up();

        switch (name) {
            case "F":
            case "E":
            case "X":
                drawing_with_state = CellState.UNDEFINED;
                break;

            default:
                return false;
        }

        return true;
    }

    private void set_mods (uint state) {
        var mods = (state & Gtk.accelerator_get_default_mod_mask ());
        control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
        other_mod_pressed = (((mods & ~Gdk.ModifierType.SHIFT_MASK) & ~Gdk.ModifierType.CONTROL_MASK) != 0);
        shift_pressed = ((mods & Gdk.ModifierType.SHIFT_MASK) != 0);
        only_control_pressed = control_pressed && !other_mod_pressed; /* Shift can be pressed */
    }

    private void on_mode_switch_changed (Gtk.Widget widget) {
        game_state = widget.get_data ("mode");
        game_state_changed (game_state);
    }

    private void on_save_game_button_clicked () {
        if (shift_pressed) {
            save_game_as_request ();
        } else {
            save_game_request ();
        }
    }

    private void on_save_game_as_button_clicked () {
        save_game_as_request ();
    }

    private void on_load_game_button_clicked () {
        open_game_request ();
    }

    private void on_check_button_pressed () {
        var errors = check_errors_request ();

        if (errors > 0) {
            send_notification (
                (ngettext (_("%u error found"), _("%u errors found"), errors)).printf (errors)
            );
        } else {
            send_notification (_("No errors"));
        }

        if (errors > 0) {
            rewind_request ();
        }
    }

    private void on_undo_button_pressed () {
        previous_move_request ();
    }

    private void on_auto_solve_button_pressed () {
        solve_this_request ();
    }

    private void on_restart_button_pressed () {
        restart_request ();
    }

    private void on_app_menu_apply () {
        var rows = app_menu.row_val;
        var cols = app_menu.column_val;
        generator_grade = (Difficulty)(app_menu.grade_val);

        if (generator_grade >= Difficulty.CHALLENGING && (rows < 15 || cols < 15)) {
            rows = rows.clamp (15, rows);
            cols = cols.clamp (15, cols);
            app_menu.row_val = rows;
            app_menu.column_val = cols;

            send_notification (_("Minimum size 15 for this difficulty"));
        }

        game_name = app_menu.title;
        dimensions = {cols, rows};
    }
}
}
