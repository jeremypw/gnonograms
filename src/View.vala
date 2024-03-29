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
    private class ProgressIndicator : Gtk.Grid {
        private Gtk.Spinner spinner;
        private Gtk.Button cancel_button;
        private Gtk.Label label;

        public string text {
            set {
                label.label = value;
            }
        }

        public Cancellable? cancellable { get; set; }

        public ProgressIndicator () {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                column_homogeneous: false,
                column_spacing: 6,
                valign: Gtk.Align.CENTER
            );
        }

        construct {
            spinner = new Gtk.Spinner ();
            label = new Gtk.Label (null);
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            add (label);
            add (spinner);

            cancel_button = new Gtk.Button ();
            var img = new Gtk.Image.from_icon_name ("process-stop-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            img.set_tooltip_text (_("Cancel solving"));
            cancel_button.image = img;
            cancel_button.no_show_all = true;
            cancel_button.get_style_context ().add_class ("warn");
            img.get_style_context ().add_class ("warn");

            add (cancel_button);

            show_all ();

            cancel_button.clicked.connect (() => {
                if (cancellable != null) {
                    cancellable.cancel ();
                }
            });

            realize.connect (() => {
                if (cancellable != null) {
                    cancel_button.show ();
                }

                spinner.start ();
            });

            unrealize.connect (() => {
                if (cancellable != null) {
                    cancellable = null;
                    cancel_button.hide ();
                }

                spinner.stop ();
            });
        }
    }

    private class HeaderButton : Gtk.Button {
        construct {
            valign = Gtk.Align.CENTER;
        }

        public HeaderButton (string icon_name, string action_name, string text) {
            Object (
                action_name: action_name,
                tooltip_markup: Granite.markup_accel_tooltip (
                    View.app.get_accels_for_action (action_name), text),
                image: new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR)
            );
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

        public RestartButton (string icon_name, string action_name, string text) {
            base (icon_name, action_name, text);
        }
    }

    private class AppMenu : Gtk.MenuButton {
        private class GradeChooser : Gtk.ComboBoxText {
            public Difficulty grade {
                get {
                    return (Difficulty)(int.parse (active_id));
                }

                set {
                    active_id = ((uint)value).clamp (MIN_GRADE, Difficulty.MAXIMUM).to_string ();
                }
            }

            public GradeChooser () {
                Object (
                    expand: false
                );

                foreach (Difficulty d in Difficulty.all_human ()) {
                    append (((uint)d).to_string (), d.to_string ());
                }
            }
        }

        private class DimensionSpinButton : Gtk.SpinButton {
            public DimensionSpinButton () {
                Object (
                    adjustment: new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
                    climb_rate: 5.0,
                    digits: 0,
                    snap_to_ticks: true,
                    orientation: Gtk.Orientation.HORIZONTAL,
                    margin_top: 3,
                    margin_bottom: 3,
                    width_chars: 3,
                    can_focus: true
                );
            }
        }

        public unowned Controller controller { get; construct; }

        public AppMenu (Controller controller) {
            Object (
                image: new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR),
                tooltip_text: _("Options"),
                controller: controller
            );
        }

        construct {
            var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU) {
                action_name = ACTION_PREFIX + ACTION_ZOOM_OUT,
                tooltip_markup = Granite.markup_accel_tooltip (
                    app.get_accels_for_action (ACTION_PREFIX + ACTION_ZOOM_OUT), _("Zoom out")
                )
            };

            var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU) {
                action_name = ACTION_PREFIX + ACTION_ZOOM_IN,
                tooltip_markup = Granite.markup_accel_tooltip (
                    app.get_accels_for_action (ACTION_PREFIX + ACTION_ZOOM_IN), _("Zoom in")
                )
            };

            var size_grid = new Gtk.Grid () {
                column_homogeneous = true,
                hexpand = true,
                margin= 12
            };
            size_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

            size_grid.add (zoom_out_button);
            size_grid.add (zoom_in_button);

            var grade_setting = new GradeChooser ();
            var row_setting = new DimensionSpinButton ();
            var column_setting = new DimensionSpinButton ();
            var title_setting = new Gtk.Entry () {
                placeholder_text = _("Enter title of game here")
            };

            var settings_grid = new Gtk.Grid () {
                orientation = Gtk.Orientation.VERTICAL,
                margin = 12,
                row_spacing = 6,
                column_homogeneous = false
            };
            settings_grid.attach (new SettingLabel (_("Name:")), 0, 0, 1);
            settings_grid.attach (title_setting, 1, 0, 3);
            settings_grid.attach (new SettingLabel (_("Difficulty:")), 0, 1, 1);
            settings_grid.attach (grade_setting, 1, 1, 3);
            settings_grid.attach (new SettingLabel (_("Rows:")), 0, 2, 1);
            settings_grid.attach (row_setting, 1, 2, 1);
            settings_grid.attach (new SettingLabel (_("Columns:")), 0, 3, 1);
            settings_grid.attach (column_setting, 1, 3, 1);

            var main_grid = new Gtk.Grid () {orientation = Gtk.Orientation.VERTICAL};
            main_grid.add (size_grid);
            main_grid.add (settings_grid);

            var app_popover = new AppPopover ();
            app_popover.add (main_grid);
            set_popover (app_popover);

            app_popover.apply_settings.connect (() => {
                controller.generator_grade = grade_setting.grade;
                controller.dimensions = {(uint)column_setting.@value, (uint)row_setting.@value};
                controller.game_name = title_setting.text; // Must come after changing dimensions
            });

            toggled.connect (() => { /* Allow parent to set values first */
                if (active) {
                    grade_setting.grade = controller.generator_grade;
                    row_setting.value = (double)(controller.dimensions.height);
                    column_setting.value = (double)(controller.dimensions.width);
                    title_setting.text = controller.game_name;
                    popover.show_all ();
                }
            });
        }

        /** Popover that can be cancelled with Escape and closed by Enter **/
        private class AppPopover : Gtk.Popover {
            private bool cancelled = false;
            public signal void apply_settings ();
            public signal void cancel ();

            construct {
                closed.connect (() => {
                    if (!cancelled) {
                        apply_settings ();
                    } else {
                        cancel ();
                    }

                    cancelled = false;
                });

                key_press_event.connect ((event) => {
                    cancelled = (event.keyval == Gdk.Key.Escape);

                    if (event.keyval == Gdk.Key.KP_Enter || event.keyval == Gdk.Key.Return) {
                        hide ();
                    }
                });
            }
        }

        private class SettingLabel : Gtk.Label {
            public SettingLabel (string text) {
                Object (
                    label: text,
                    xalign: 1.0f,
                    margin_end: 6
                );
            }
        }
    }

    private const double USABLE_MONITOR_HEIGHT = 0.85;
    private const double USABLE_MONITOR_WIDTH = 0.95;
    private const int GRID_BORDER = 6;
    private const int GRID_COLUMN_SPACING = 6;
    private const double TYPICAL_MAX_BLOCKS_RATIO = 0.3;
    private const double ZOOM_RATIO = 0.05;
    private const uint PROGRESS_DELAY_MSEC = 500;

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

    public View (Model _model, Controller controller) {
        Object (
            model: _model,
            controller: controller,
            resizable: false,
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
        action_accelerators.set (ACTION_PAINT_FILLED, "F");
        action_accelerators.set (ACTION_PAINT_EMPTY, "E");
        action_accelerators.set (ACTION_PAINT_UNKNOWN, "X");
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
        app_menu = new AppMenu (controller) {
            tooltip_markup = Granite.markup_accel_tooltip (app.get_accels_for_action (ACTION_PREFIX + ACTION_OPTIONS), _("Options"))
        };

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

        header_bar = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = true,
            custom_title = progress_stack
        };
        header_bar.get_style_context ().add_class ("gnonograms-header");
        header_bar.pack_start (load_game_button);
        header_bar.pack_start (save_game_button);
        header_bar.pack_start (save_game_as_button);
        header_bar.pack_start (restart_button);
        header_bar.pack_start (undo_button);
        header_bar.pack_start (redo_button);
        header_bar.pack_start (check_correct_button);
        header_bar.pack_end (app_menu);
        header_bar.pack_end (generate_button);
        header_bar.pack_end (mode_switch);
        header_bar.pack_end (auto_solve_button);
        header_bar.pack_end (hint_button);

        toast = new Granite.Widgets.Toast ("") {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        toast.set_default_action (null);

        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, this);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, this);
        cell_grid = new CellGrid (this);

        main_grid = new Gtk.Grid () {
            row_spacing = 0,
            column_spacing = GRID_COLUMN_SPACING,
            border_width = GRID_BORDER,
            expand = true
        };
        main_grid.attach (row_clue_box, 0, 1, 1, 1); /* Clues fordimensions.height*/
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

            if (drawing_with_state != CellState.UNDEFINED) {
                make_move_at_cell ();
            }
        });

        notify["strikeout-complete"].connect (() => {
            update_all_labels_completeness ();
        });

        controller.notify["dimensions"].connect (() => {
            // Update cell-size if required to fit on screen but without changing window size unnecessarily
            // The dimensions may have increased or decreased so may need to increase or decrease cell size
            // It is assumed up to 90% of the screen area can be used
            var monitor_area = Gdk.Rectangle () {
                width = 1024,
                height = 768
            };

            Gdk.Window? window = get_window ();
            if (window != null) {
                monitor_area = Utils.get_monitor_area (screen, window);
            }

            var available_screen_width = monitor_area.width * 0.9 - 2 * GRID_BORDER - GRID_COLUMN_SPACING;
            var max_cell_width = available_screen_width / (controller.dimensions.width * (1.0 + GRID_LABELBOX_RATIO));

            var available_grid_height = (int)(window.get_height () - header_bar.get_allocated_height () - 2 * GRID_BORDER);
            var opt_cell_height = (int)(available_grid_height / (controller.dimensions.height * (1.0 + GRID_LABELBOX_RATIO)));

            var available_screen_height = monitor_area.height * 0.9 - header_bar.get_allocated_height () - 2 * GRID_BORDER;
            var max_cell_height = available_screen_height / (controller.dimensions.height * (1.0 + GRID_LABELBOX_RATIO));

            var max_cell_size = (int)(double.min (max_cell_width, max_cell_height));
            if (max_cell_size < cell_size) {
                cell_size = max_cell_size;
            } else if (cell_size < opt_cell_height) {
                cell_size = int.min (max_cell_size, opt_cell_height);
            }

        });

       cell_grid.leave_notify_event.connect (() => {
            row_clue_box.unhighlight_all ();
            column_clue_box.unhighlight_all ();
            return false;
        });

        cell_grid.button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS || event.button == Gdk.BUTTON_MIDDLE) {
                drawing_with_state = controller.game_state == GameState.SOLVING ? CellState.UNKNOWN : CellState.EMPTY;
            } else {
                drawing_with_state = event.button == Gdk.BUTTON_PRIMARY ? CellState.FILLED : CellState.EMPTY;
            }

            make_move_at_cell ();
            return true;
        });

        key_release_event.connect ((event) => {
            if (event.keyval == drawing_with_key) {
                stop_painting ();
            }

            return false;
        });

        cell_grid.button_release_event.connect (stop_painting);
        // Force window to follow grid size in both native and flatpak installs
        cell_grid.size_allocate.connect ((alloc) => {
            Idle.add (() => {
                var width = alloc.width * (1 + GRID_LABELBOX_RATIO);
                var height = alloc.height * (1 + GRID_LABELBOX_RATIO);
                resize ((int)width, (int)height);
                return Source.REMOVE;
            });
        });

        show_all ();
    }

    public string[] get_clues (bool is_column) {
        var label_box = is_column ? column_clue_box : row_clue_box;
        return label_box.get_clues ();
    }

    public void update_labels_from_string_array (string[] clues, bool is_column) {
        var clue_box = is_column ? column_clue_box : row_clue_box;
        var lim = is_column ? controller.dimensions.width : controller.dimensions.height;

        for (int i = 0; i < lim; i++) {
            clue_box.update_label_text (i, clues[i]);
        }
    }

    public void update_labels_from_solution () {
        for (int r = 0; r < controller.dimensions.height; r++) {
            row_clue_box.update_label_text (r, model.get_label_text_from_solution (r, false));
        }

        for (int c = 0; c < controller.dimensions.width; c++) {
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
            update_label_complete (r, false);
        }

        for (int c = 0; c < controller.dimensions.width; c++) {
            update_label_complete (c, true);
        }
    }

    private void update_label_complete (uint idx, bool is_col) {
        var lbox = is_col ? column_clue_box : row_clue_box;

        if (controller.game_state == GameState.SOLVING && strikeout_complete) {
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
        app_menu.activate ();
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
    }
    private void action_paint_empty () {
        paint_cell_state (CellState.EMPTY);
    }
    private void action_paint_unknown () {
        paint_cell_state (CellState.UNKNOWN);
    }
    private void paint_cell_state (CellState cs) {
        if (cs == CellState.UNKNOWN && controller.game_state != GameState.SOLVING) {
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
