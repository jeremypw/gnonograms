/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.PreferenceRow : Gtk.Box {
    public string text { get; construct; }
    public Gtk.Widget widget { get; construct; }
    public PreferenceRow (string text, Gtk.Widget setting_widget) {
        Object (
            text: text,
            widget: setting_widget
        );
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        margin_top = 3;
        margin_bottom = 6;
        spacing = 12;
        hexpand = true;

        var label = new Gtk.Label (text) {
            halign = Gtk.Align.START
        };

        widget.halign = Gtk.Align.END;
        widget.hexpand = true;

        append (label);
        append (widget);
    }
}
