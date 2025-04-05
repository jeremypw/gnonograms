/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
    public class Gnonograms.ProgressIndicator : Gtk.Box {
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
                homogeneous: false,
                spacing: 6,
                valign: Gtk.Align.CENTER
            );
        }

        construct {
            spinner = new Gtk.Spinner ();
            label = new Gtk.Label (null);
            label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

            append (label);
            append (spinner);

            cancel_button = new Gtk.Button ();
            var img = new Gtk.Image.from_icon_name ("process-stop-symbolic") {
                tooltip_text = _("Cancel solving")
            };
            cancel_button.child = img;
            cancel_button.add_css_class ("warn");
            cancel_button.add_css_class ("flat");
            img.add_css_class ("warn");

            append (cancel_button);

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
