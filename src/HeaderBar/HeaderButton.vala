/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
    public class Gnonograms.HeaderButton : Gtk.Button {
        public HeaderButton (string icon_name, string action_name, string text) {
            Object (
                action_name: action_name,
                tooltip_markup: Granite.markup_accel_tooltip (
                    View.app.get_accels_for_action (action_name), text
                ),
                valign: Gtk.Align.CENTER
            );

            var image = new Gtk.Image.from_icon_name (icon_name) {
                pixel_size = 24
            };

            child = image;
            add_css_class ("flat");
        }
    }
