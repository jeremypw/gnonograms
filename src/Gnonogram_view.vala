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
    private Gnonograms.LabelBox row_clue_box;
    private Gnonograms.LabelBox column_clue_box;
    private CellGrid cell_grid;
    private Gtk.HeaderBar header_bar;
    private AppMenu app_menu;
    private ModeButton mode_switch;
    private Gtk.Button random_game_button;
    private HistoryControl history;
    private Model model {get; set;}

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
                    get_default_fontheight_from_dimensions ();
                }
            }
        }
    }

    public uint rows {get { return dimensions.height; }}
    public uint cols {get { return dimensions.width; }}

    private double _fontheight;
    public double fontheight {
        set {
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
            if (_game_state != value) {
                _game_state = value;
                mode_switch.mode = value;
                cell_grid.game_state = value;

                if (value == GameState.SETTING) {
                    header_bar.subtitle = _("Setting");
                } else {
                    header_bar.subtitle = _("Solving");
                }

                update_labels_from_model ();
            }
        }
    }

    public string header_title {
        set {
            header_bar.title = value;
        }
    }

    public signal void new_random ();

    construct {
        title = _("Gnonograms for Elementary");
        window_position = Gtk.WindowPosition.CENTER_ALWAYS;
        resizable = false;

        if (Granite.Services.Logger.DisplayLevel != Granite.Services.LogLevel.DEBUG) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        }

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/gnonograms/icons");

        header_bar = new Gtk.HeaderBar ();
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        random_game_button = new Gtk.Button ();
        var img = new Gtk.Image.from_icon_name ("gnonogram-puzzle", Gtk.IconSize.LARGE_TOOLBAR);
        random_game_button.image = img;
        random_game_button.clicked.connect (() => {new_random ();});

        header_bar.pack_start (random_game_button);

        history = new HistoryControl ();
        header_bar.pack_start (history);

        mode_switch = new ModeButton ();

        header_bar.pack_start (mode_switch);

        set_titlebar (header_bar);
    }

    public View (Dimensions dimensions, uint grade, Model model) {
        Object (dimensions: dimensions);

        this.model = model;
        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, dimensions);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, dimensions);
        cell_grid = new CellGrid (model);
        app_menu = new AppMenu (dimensions, grade);
        header_bar.pack_end (app_menu);

        var grid = new Gtk.Grid ();
        grid.row_spacing = (int)FRAME_WIDTH;
        grid.column_spacing = (int)FRAME_WIDTH;
        grid.border_width = (int)FRAME_WIDTH;
        grid.attach (row_clue_box, 0, 1, 1, 2); /* Clues for rows */
        grid.attach (column_clue_box, 1, 0, 2, 1); /* Clues for columns */
        grid.attach (cell_grid, 1, 1, 2, 2);

        add (grid);

        get_default_fontheight_from_dimensions ();
        show_all ();
    }

    private void connect_signals () {
        cell_grid.cursor_moved.connect (on_grid_cursor_moved);
        cell_grid.leave_notify_event.connect (on_grid_leave);
        cell_grid.button_press_event.connect (on_grid_button_press);
        cell_grid.button_release_event.connect (on_grid_button_release);

        mode_switch.mode_changed.connect (on_mode_switch_changed);

        app_menu.apply.connect (on_app_menu_apply);

        history.go_back.connect (on_history_go_back);
        history.go_forward.connect (on_history_go_forward);

        key_press_event.connect (on_key_press_event);
        key_release_event.connect (on_key_release_event);
    }

    private double get_default_fontheight_from_dimensions () {
        double max_h, max_w;
        Gdk.Rectangle rect;
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

        return double.min (max_h, max_w) / 2.5;
    }

    private void update_labels_from_model () {
        for (int r = 0; r < rows; r++) {
            row_clue_box.update_label_text (r, model.get_label_text (r, false));
        }

        for (int c = 0; c < cols; c++) {
            column_clue_box.update_label_text (c, model.get_label_text (c, true));
        }
    }

    /*** Signal handlers ***/

    private void on_grid_cursor_moved (Cell from, Cell to) {}
    private bool on_grid_leave () {return false;}
    private bool on_grid_button_press (Gdk.EventButton event) {return false;}
    private bool on_grid_button_release () {return false;}
    private void on_mode_switch_changed (Gtk.Widget widget) {}
    private void on_app_menu_apply () {}
    private void on_history_go_back (Move m) {}
    private void on_history_go_forward (Move m) {}
    private bool on_key_press_event () {return false;}
    private bool on_key_release_event () {return false;}

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

        construct {
            var setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU); /* provisional only */
            var solving_icon = new Gtk.Image.from_icon_name ("process-working-symbolic", Gtk.IconSize.MENU);  /* provisional only */

            setting_icon.set_data ("mode", GameState.SETTING);
            solving_icon.set_data ("mode", GameState.SOLVING);

            setting_index = append (setting_icon);
            solving_index = append (solving_icon);
        }
    }
}
}
