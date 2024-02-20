/* Copyright (C) 2010-2022 Jeremy Wootten
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
