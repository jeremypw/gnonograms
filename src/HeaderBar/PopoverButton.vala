/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.PopoverButton : Gtk.Button {
    public string text { get; construct; }
    public string detailed_action { get; construct; }

    public PopoverButton (string _text, string? _action_name = null) {
        Object (
            text: _text,
            detailed_action: _action_name // Assigning directly to Gtk.Button.action_name doesnt work for some reason
        );
    }

    construct {
        margin_top = 3;
        margin_bottom = 3;
        add_css_class (Granite.STYLE_CLASS_FLAT);
        set_action_name (detailed_action);
        if (text != null && detailed_action != null) {
            var accels = ((Gtk.Application) Application.get_default ()).get_accels_for_action (detailed_action);
            if (accels != null) {
                child = new Granite.AccelLabel (text, accels[0]);
                return;
            } 
        }

        child = new Gtk.Label (text);
    }
}
