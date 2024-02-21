/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
    private class Gnonograms.RestartButton : Gnonograms.HeaderButton {
        public bool restart_destructive { get; set; }

        construct {
            restart_destructive = false;
            notify["restart-destructive"].connect (() => {
                if (restart_destructive) {
                    add_css_class ("warn");
                    remove_css_class ("dim");
                } else {
                    remove_css_class ("warn");
                    add_css_class ("dim");
                }
            });

            bind_property ("sensitive", this, "restart-destructive");
        }

        public RestartButton (string icon_name, string action_name, string text) {
            base (icon_name, action_name, text);
        }
    }
