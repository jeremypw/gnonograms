/* View class for gnonograms-elementary - displays user interface
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
public class View : Gtk.ApplicationWindow {
    private const uint NOTIFICATION_TIMEOUT_SEC = 2;
    private Gnonograms.LabelBox row_clue_box;
    private Gnonograms.LabelBox column_clue_box;
    private CellGrid cell_grid;
    private ResizeWidget row_resizer;
    private ResizeWidget col_resizer;
    private Gtk.HeaderBar header_bar;
    private AppMenu app_menu;
    private Granite.Widgets.Toast toast;

    private ModeButton mode_switch;
    private Gtk.Button load_game_button;
    private Gtk.Button save_game_button;
    private Gtk.Button random_game_button;
    private Gtk.Button check_correct_button;
    private Model model {get; set;}
    private CellState drawing_with_state;

    private Dimensions _dimensions;
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            if (value != _dimensions) {
                _dimensions = value;
                /* Do not update during construction */
                if (row_clue_box != null) {
                    row_clue_box.dimensions = dimensions;
                    column_clue_box.dimensions = dimensions;
                    set_default_fontheight_from_dimensions ();
                    row_resizer.set_value (dimensions.height);
                    app_menu.row_val = dimensions.height;
                    col_resizer.set_value (dimensions.width);
                    app_menu.column_val = dimensions.width;
                    resized (dimensions);
                    queue_draw ();
                }
            }
        }
    }

    private Difficulty _grade = 0;
    public Difficulty grade {
        get {
            return _grade;
        }

        set {
            _grade = value;
            app_menu.grade_val = (uint)grade;
        }
    }

    public uint rows {get { return dimensions.height; }}
    public uint cols {get { return dimensions.width; }}

    private double _fontheight;
    public double fontheight {
        set {
            if (value < 1) {
                set_default_fontheight_from_dimensions ();
                return;
            }

            _fontheight = value;
            row_clue_box.fontheight = value;
            column_clue_box.fontheight = value;
        }

        get {
            return _fontheight;
        }
    }

    private GameState _game_state;
    public GameState game_state {
        get {
            return _game_state;
        }

        set {
            _game_state = value;
            mode_switch.mode = value;
            cell_grid.game_state = value;

            if (value == GameState.SETTING) {
                header_bar.subtitle = _("Setting");
                update_labels_from_model ();
            } else {
                header_bar.subtitle = _("Solving");
            }
        }
    }

    private bool is_solving {get {return game_state == GameState.SOLVING;}}

    public string header_title {
        get {
            return header_bar.title;
        }

        set {
            header_bar.title = value;
        }
    }

    private Cell current_cell {
        get {
            return cell_grid.current_cell;
        }
        set {
            cell_grid.current_cell = value;
        }
    }

    public bool can_go_back {
        set {
            check_correct_button.sensitive = value && is_solving;
        }
    }

    private bool mods {
        get {
            return control_pressed || other_mod_pressed;
        }
    }

    private bool control_pressed = false;
    private bool other_mod_pressed = false;
    private bool shift_pressed = false;
    private bool only_control_pressed = false;

    public signal void random_game_request ();
    public signal uint check_errors_request ();
    public signal void rewind_request ();
    public signal bool next_move_request ();
    public signal bool previous_move_request ();
    public signal void save_game_request ();
    public signal void save_game_as_request ();
    public signal void open_game_request ();

    public signal void resized (Dimensions dim);
    public signal void moved (Cell cell);
    public signal void game_state_changed (GameState gs);



    construct {
        resizable = false;
        drawing_with_state = CellState.UNDEFINED;

        if (Granite.Services.Logger.DisplayLevel != Granite.Services.LogLevel.DEBUG) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        }

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/gnonograms/icons");
        header_bar = new Gtk.HeaderBar ();
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        title = _("Gnonograms for Elementary");

        load_game_button = new Gtk.Button ();
        var img = new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        load_game_button.image = img;
        load_game_button.tooltip_text = _("Load a Game from File");
        load_game_button.clicked.connect (() => {open_game_request ();});
        header_bar.pack_start (load_game_button);

        save_game_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        save_game_button.image = img;
        save_game_button.tooltip_text = _("Save a Game to File");
        save_game_button.button_release_event.connect ((event) => {
            set_mods (event.state);
            return false;
        });

        save_game_button.clicked.connect (() => {
            if (shift_pressed) {
                save_game_as_request ();
            } else {
                save_game_request ();
            }
        });
        header_bar.pack_start (save_game_button);

        random_game_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        random_game_button.image = img;
        random_game_button.tooltip_text = _("Generate a Random Game");
        random_game_button.clicked.connect (() => {random_game_request ();});
        header_bar.pack_start (random_game_button);

        check_correct_button = new Gtk.Button ();
        img = new Gtk.Image.from_icon_name ("media-seek-backward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        check_correct_button.image = img;
        check_correct_button.tooltip_text = _("Undo Any Errors");
        check_correct_button.clicked.connect (on_check_button_pressed);
        check_correct_button.sensitive = false;
        header_bar.pack_start (check_correct_button);

        app_menu = new AppMenu ();
        header_bar.pack_end (app_menu);

        mode_switch = new ModeButton ();
        header_bar.pack_end (mode_switch);

        toast = new Granite.Widgets.Toast ("");
        toast.set_default_action (null);
        toast.set_size_request (200, -1);
        toast.hexpand = false;

        set_titlebar (header_bar);

        row_resizer = new ResizeWidget (Gtk.Orientation.VERTICAL, _("Set Number of Rows"));
        col_resizer = new ResizeWidget (Gtk.Orientation.HORIZONTAL, _("Set Number of Columns"));
    }

    public View (Model model) {
        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL);
        cell_grid = new CellGrid (model);

        this.model = model;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 0;
        grid.column_spacing = 0;
        grid.row_spacing = 0;
        grid.border_width = 0;
        grid.attach (toast, 0, 0, 1, 1);
        grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues for rows */
        grid.attach (column_clue_box, 1, 0, 1, 1); /* Clues for columns */
        grid.attach (cell_grid, 1, 1, 1, 1);

        grid.attach (col_resizer, 1, 2, 1, 1);
        grid.attach (row_resizer, 2, 1, 1, 1);

        add (grid);

        connect_signals ();
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

    private void connect_signals () {
        realize.connect (() => {
            update_labels_from_model ();
        });

        cell_grid.cursor_moved.connect (on_grid_cursor_moved);
        cell_grid.leave_notify_event.connect (on_grid_leave);
        cell_grid.button_press_event.connect (on_grid_button_press);
        cell_grid.button_release_event.connect (on_grid_button_release);

        mode_switch.mode_changed.connect (on_mode_switch_changed);

        key_press_event.connect (on_key_press_event);
        key_release_event.connect (on_key_release_event);

        row_resizer.changed.connect (on_dimensions_changed);
        col_resizer.changed.connect (on_dimensions_changed);

        app_menu.apply.connect (on_app_menu_apply);
    }

    private void set_default_fontheight_from_dimensions () {
        double max_h, max_w;
        Gdk.Rectangle rect;

        if (get_window () == null) {
            return;
        }

#if HAVE_GDK_3_22
        var display = Gdk.Display.get_default();
        var monitor = display.get_monitor_at_window (get_window ());
        monitor.get_geometry (out rect);
#else
        var screen = Gdk.Screen.get_default();
        var monitor = screen.get_monitor_at_window (get_window ());
        screen.get_monitor_geometry (monitor, out rect);
#endif
        max_h = (double)(rect.height) / ((double)(rows * 2));
        max_w = (double)(rect.width) / ((double)(cols * 2));

        fontheight = double.min (max_h, max_w) / 2;
    }

    public void update_labels_from_model () {
        for (int r = 0; r < rows; r++) {
            row_clue_box.update_label_text (r, model.get_label_text (r, false));
        }

        for (int c = 0; c < cols; c++) {
            column_clue_box.update_label_text (c, model.get_label_text (c, true));
        }
    }

    public void update_labels_from_string_array (string[] clues, bool is_column) {
        var clue_box = is_column ? column_clue_box : row_clue_box;
        var lim = is_column ? cols : rows;

        for (int i = 0; i < lim; i++) {
            clue_box.update_label_text (i, clues[i]);
        }
    }

    private void update_labels_for_cell (Cell cell) {
        row_clue_box.update_label_text (cell.row, model.get_label_text (cell.row, false));
        column_clue_box.update_label_text (cell.col, model.get_label_text (cell.col, true));
    }

    private void highlight_labels (Cell c, bool is_highlight) {
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void make_move_at_cell (CellState state = drawing_with_state, Cell target = current_cell) {
        if (state != CellState.UNDEFINED) {
            Cell cell = target.clone ();
            cell.state = state;
            moved (cell);
            mark_cell (cell);
            cell_grid.highlight_cell (cell, true);
        }
    }

    public void make_move (Move m) {
        move_cursor_to (m.cell);
        mark_cell (m.cell);

        queue_draw ();
    }

    private void move_cursor_to (Cell to, Cell from = current_cell) {
        highlight_labels  (from, false);
        highlight_labels (to, true);
        current_cell = to;
    }

    private void mark_cell (Cell cell) {
        assert (cell.state != CellState.UNDEFINED);

        if (!is_solving) {
            update_labels_for_cell (cell);
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

    public void send_notification (string text) {
        toast.title = text;
        toast.send_notification ();
        Timeout.add_seconds (NOTIFICATION_TIMEOUT_SEC, () => {
            toast.reveal_child = false;
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
        switch (event.button) {
            case Gdk.BUTTON_PRIMARY:
            case Gdk.BUTTON_MIDDLE:
                if (event.type == Gdk.EventType.@2BUTTON_PRESS || event.button == Gdk.BUTTON_MIDDLE) {
                    if (is_solving) {
                        drawing_with_state = CellState.UNKNOWN;
                        break;
                    } else {
                        return true;
                    }
                } else {
                    drawing_with_state = CellState.FILLED;
                }
                break;

            case Gdk.BUTTON_SECONDARY:
                drawing_with_state = CellState.EMPTY;
                break;

            default:
                return false;
        }

        make_move_at_cell ();
        return true;
    }

    private bool on_grid_button_release () {
        drawing_with_state = CellState.UNDEFINED;
        return true;
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

    private void on_dimensions_changed () {
        dimensions = {col_resizer.get_value (), row_resizer.get_value ()};
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


    public void on_app_menu_apply () {
        grade = (Difficulty)(app_menu.grade_val);
    }


    /** Private classes **/
    private class ModeButton : Granite.Widgets.ModeButton {
        private int setting_index;
        private int solving_index;

        public GameState mode {
            set {
                if (value == GameState.SETTING) {
                    set_active (setting_index);
                } else {
                    set_active (solving_index);
                }
            }
        }

        public ModeButton () {
            var setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU); /* provisional only */
            var solving_icon = new Gtk.Image.from_icon_name ("process-working-symbolic", Gtk.IconSize.MENU);  /* provisional only */

            setting_icon.set_data ("mode", GameState.SETTING);
            solving_icon.set_data ("mode", GameState.SOLVING);

            setting_icon.tooltip_text = _("Draw a pattern");
            solving_icon.tooltip_text = _("Solve a puzzle");

            setting_index = append (setting_icon);
            solving_index = append (solving_icon);
        }
    }

/** Scale limited to integral values separated by step (interface uses uint) **/
    private class ResizeScale : Gtk.Grid {
        private uint step;
        private Gtk.Scale scale;
        private Gtk.Label val_label;

        construct {
            val_label = new Gtk.Label ("0");
            val_label.show_all ();

            row_spacing = 12;
            column_spacing = 6;
            border_width = 12;
        }

        public ResizeScale (Gtk.Orientation orientation, uint _start, uint _end, uint _step) {
            scale = new Gtk.Scale (orientation, null);

            var start = (double)_start / (double)_step;
            var end = (double)_end / (double)_step + 1.0;
            step = _step;
            var adjustment = new Gtk.Adjustment (start, start, end, 1.0, 1.0, 1.0);
            scale.adjustment = adjustment;

            for (var val = start; val <= end; val += 1.0) {
                scale.add_mark (val, Gtk.PositionType.BOTTOM, null);
            }

            scale.draw_value = false;

            scale.value_changed.connect (() => {
                val_label.label = get_value ().to_string ();
            });

            if (orientation == Gtk.Orientation.HORIZONTAL) {
                scale.hexpand = true;
                val_label.xalign = 1;
                attach (val_label, 0, 0, 1, 1);
                attach (scale, 1, 0, 1, 1);
            } else {
                scale.vexpand = true;
                val_label.yalign = 1;
                attach (val_label, 0, 0, 1, 1);
                attach (scale, 0, 1, 1, 1);
            }
        }

        public uint get_value () {
            return (uint)(scale.get_value ()) * step;
        }

        public void set_value (uint val) {
            scale.set_value ((double)val / (double)step);
            scale.value_changed ();
        }
    }

    private class ResizeWidget : Gtk.EventBox {
        private Gtk.Grid grid;
        private Gtk.Revealer scale_revealer;
        private Gtk.Revealer image_revealer;
        private ResizeScale scale;

        private Gtk.Image image1;
        private Gtk.Image image2;

        private uint last_value = 0;

        public signal void changed (uint val);

        construct {
            scale_revealer = new Gtk.Revealer ();
            image_revealer = new Gtk.Revealer ();

            grid = new Gtk.Grid ();
            grid.set_border_width (0);
            add (grid);

            enter_notify_event.connect (on_enter);
            leave_notify_event.connect (on_leave);
        }

        public ResizeWidget (Gtk.Orientation orientation, string? tip = null) {
            scale = new ResizeScale (orientation, 5, 50, 5);
            scale_revealer.add (scale);


            if (tip != null) {
                tooltip_text = tip;
            }

            Gtk.Box image_box = new Gtk.Box (orientation, 0);

            if (orientation == Gtk.Orientation.HORIZONTAL) {
                image1 = new Gtk.Image.from_icon_name ("pan-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                image2 = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            } else {
                image1 = new Gtk.Image.from_icon_name ("pan-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                image2 = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            }

            image_box.pack_start (image1, false, false, 0);
            image_box.pack_end (image2, false, false, 0);
            image_revealer.add (image_box);

            if (orientation == Gtk.Orientation.HORIZONTAL) {
            scale_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            image_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                grid.attach (scale_revealer, 0, 0, 1, 1);
                grid.attach (image_revealer, 0, 1, 1, 1);
            } else {
            scale_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
            image_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
                grid.attach (scale_revealer, 0, 0, 1, 1);
                grid.attach (image_revealer, 1, 0, 1, 1);
            }

            show_scale (false);
        }

        private uint reveal_timeout_id = 0;
        private const uint REVEAL_DELAY_MSEC = 100;
        public void show_scale (bool show) {
            if (reveal_timeout_id > 0) {
                Source.remove (reveal_timeout_id);
                reveal_timeout_id = 0;
            } else {
                reveal_timeout_id = Timeout.add (REVEAL_DELAY_MSEC, () => {
                    scale_revealer.set_reveal_child (show);
                    image_revealer.set_reveal_child (!show);
                    reveal_timeout_id = 0;
                    return false;
                });
            }
        }

        public void set_value (uint val) {
            scale.set_value (val);
            last_value = scale.get_value ();
        }

        public uint get_value () {
            return scale.get_value ();
        }

        private bool on_enter () {
            show_scale (true);
            last_value = scale.get_value ();
            return false;
        }

        private bool on_leave () {
            show_scale (false);
            var val = scale.get_value ();
            if (last_value != val) {
                last_value = val;
                changed (val);
            }

            return false;
        }
    }
}
}
