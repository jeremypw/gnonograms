/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.HeaderBarFactory : Object {

    public View view { get; construct; }

    private Gtk.HeaderBar header_bar;
    private Gtk.Label title_label;
    private Gtk.Stack progress_stack;
    private ProgressIndicator progress_indicator;
    private Gtk.Button generate_button;
    private Gtk.Button undo_button;
    private Gtk.Button redo_button;
    private Gtk.Button check_correct_button;
    private Gtk.Button hint_button;
    private Granite.ModeSwitch mode_switch;
    private AppPopover app_popover;
    private Gtk.Button auto_solve_button;
    private Gtk.Button restart_button;

    public HeaderBarFactory (Gnonograms.View view) {
        Object (
            view: view
        );
    }

    construct {
        var app = (Gnonograms.App) Application.get_default ();
        header_bar = new Gtk.HeaderBar ();
        undo_button = new HeaderButton (
            "edit-undo-symbolic",
            ACTION_PREFIX + ACTION_UNDO,
            _("Undo Last Move")
        );
        redo_button = new HeaderButton (
            "edit-redo-symbolic",
            ACTION_PREFIX + ACTION_REDO,
            _("Redo Last Move")
        );
        check_correct_button = new HeaderButton (
            "media-seek-backward-symbolic",
            ACTION_PREFIX + ACTION_CHECK_ERRORS,
            _("Check for Errors")
        );
        restart_button = new RestartButton (
            "view-refresh-symbolic",
            ACTION_PREFIX + ACTION_RESTART,
            _("Start again")
        ) {
            margin_end = 12,
            margin_start = 12,
        };
        hint_button = new HeaderButton (
            "help-contents-symbolic",
            ACTION_PREFIX + ACTION_HINT,
            _("Suggest next move")
        );
        auto_solve_button = new HeaderButton (
            "computer-symbolic",
            ACTION_PREFIX + ACTION_COMPUTER_SOLVE,
            _("Check whether design is solvable")
        );
        generate_button = new HeaderButton (
            "list-add",
            ACTION_PREFIX + ACTION_GENERATING_MODE,
            _("Generate New Puzzle")
        );

        app_popover = new AppPopover ();

        var menu_button = new Gtk.MenuButton () {
            tooltip_markup = Granite.markup_accel_tooltip (
                app.get_accels_for_action (
                    ACTION_PREFIX + ACTION_OPTIONS),
                    _("Options")
            ),
            icon_name = "open-menu-symbolic",
            valign = Gtk.Align.CENTER,
            popover = app_popover
        };

        // Unable to set markup on Granite.ModeSwitch so fake a Granite accelerator tooltip for now.
        mode_switch = new Granite.ModeSwitch.from_icon_name (
            "edit-symbolic",
            "system-run-symbolic"
        ) {
            margin_end = 12,
            margin_start = 12,
            valign = Gtk.Align.CENTER,
            primary_icon_tooltip_text = "%s\n%s".printf (_("Edit a Game"), "Ctrl + 1"),
            secondary_icon_tooltip_text = "%s\n%s".printf (_("Manually Solve"), "Ctrl + 2")
        };

        mode_switch.notify["active"].connect (() => {
            if (mode_switch.active) {
                mode_switch.activate_action (ACTION_PREFIX + ACTION_SOLVING_MODE, null);
            } else {
                mode_switch.activate_action (ACTION_PREFIX + ACTION_SETTING_MODE, null);
            }
        });

        progress_indicator = new ProgressIndicator ();

        title_label = new Gtk.Label ("Gnonograms") {
            use_markup = true,
            xalign = 0.5f
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        progress_stack = new Gtk.Stack () {
            halign = Gtk.Align.CENTER,
        };
        progress_stack.add_named (progress_indicator, "Progress");
        progress_stack.add_named (title_label, "Title");
        progress_stack.set_visible_child_name ("Title");

        header_bar = new Gtk.HeaderBar () {
            show_title_buttons = true,
            title_widget = progress_stack
        };
        header_bar.add_css_class ("gnonograms-header");
        header_bar.pack_start (generate_button);
        header_bar.pack_start (hint_button);
        header_bar.pack_start (restart_button);
        header_bar.pack_start (undo_button);
        header_bar.pack_start (redo_button);
        header_bar.pack_start (check_correct_button);
        header_bar.pack_end (menu_button);
        header_bar.pack_end (mode_switch);
        header_bar.pack_end (auto_solve_button);

        view.bind_property (
            "restart-destructive",
            restart_button, "restart-destructive",
            BindingFlags.SYNC_CREATE
        );

    }

    public Gtk.HeaderBar get_headerbar () {
        return header_bar;
    }

    public void on_game_state_changed (GameState gs) {
        if (gs == GENERATING) {
            generate_button.sensitive = false;
            return;
        }

        generate_button.sensitive = true;


        var is_solving = gs == SOLVING;
        var is_setting = gs == SETTING;
        var sensitive = (is_setting || is_solving);

        mode_switch.active = !is_setting;
        mode_switch.sensitive = sensitive;

        hint_button.sensitive = sensitive && is_solving;
        auto_solve_button.sensitive = is_setting;
    }

    public void popdown_menus () {
        app_popover.popdown ();
    }

    public void on_can_go_changed (bool forward, bool back) {
        check_correct_button.sensitive = back;
        undo_button.sensitive = back;
        redo_button.sensitive = forward;
    }

    public void update_title (string name, string path, Difficulty grade) {
        title_label.label = name;
        title_label.tooltip_text = path;
        progress_stack.set_visible_child_name ("Title");
    }

    public void show_working (string text) {
        progress_indicator.text = text;
    }

    public void hide_progress (Difficulty game_grade) {
        progress_stack.set_visible_child_name ("Title");
    }

    public void show_progress (Cancellable? cancellable) {
        progress_indicator.cancellable = cancellable;
        progress_stack.set_visible_child_name ("Progress");
    }
}
