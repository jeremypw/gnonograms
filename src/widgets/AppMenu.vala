/* Displays clues for gnonograms-elementary
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

namespace Gnonograms {

class AppMenu : Gtk.MenuButton {
    private AppPopover app_popover;
    private AppScale grade_scale;
    private Gtk.Label grade_label;

    private uint _grade_val;
    public uint grade_val {
        get {
            return _grade_val;
        }

        set {
            _grade_val = value;
            grade_scale.set_value (value);
            grade_label.label = Gnonograms.difficulty_to_string ((Difficulty)value);
        }
    }

    public signal void apply ();

    construct {
        popover = new AppPopover (this);
        app_popover = (AppPopover)popover;

        var grid = new Gtk.Grid ();
        popover.add (grid);
        grade_scale = new AppScale (0, Difficulty.MAXIMUM, 1);

        grade_scale.scale.value_changed.connect ((range) => {
            var val = (uint)(range.get_value ());
            var s = Gnonograms.difficulty_to_string ((Difficulty)(val));
            if (s != grade_label.label) {
                grade_label.label = s;
            }
        });

        grade_label = new Gtk.Label ("");
        grade_label.xalign = 1;
        grade_label.set_size_request (100, -1); /* So size does not change depending on text */

        grid.attach (grade_label, 0, 0, 1, 1);
        grid.attach (grade_scale, 1, 0, 1, 1);

        grid.row_spacing = 12;
        grid.column_spacing = 6;
        grid.border_width = 12;

        clicked.connect (() => {
            store_values ();
            popover.show_all ();
        });

        app_popover.apply_settings.connect (() => {
            store_values ();
            apply ();
        });

        app_popover.cancel.connect (() => {
            restore_values ();
        });
    }

    public AppMenu () {
        image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        tooltip_text = _("Options");
    }

    private void store_values () {
        grade_val = (uint)(grade_scale.get_value ());
    }

    private void restore_values () {
        grade_scale.set_value (grade_val);
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

        public AppPopover (Gtk.Widget widget) {
            Object (relative_to: widget);
        }
    }

    /** Scale limited to integral values separated by step (interface uses uint) **/
    private class AppScale : Gtk.Grid {
        private uint step;
        public Gtk.HScale scale {get; private set;}
        private Gtk.Label val_label;

        construct {
            scale = new Gtk.HScale (null);
            val_label = new Gtk.Label (null);
            val_label.xalign = 1;

            attach (val_label, 0, 0, 1, 1);
            attach (scale, 1, 0, 1, 1);

            row_spacing = 12;
            column_spacing = 6;
            border_width = 12;
        }

        public AppScale (uint _start, uint _end, uint _step) {
            var start = (double)_start / (double)_step;
            var end = (double)_end / (double)_step + 1.0;
            step = _step;
            var adjustment = new Gtk.Adjustment (start, start, end, 1.0, 1.0, 1.0);
            scale.adjustment = adjustment;

            for (var val = start; val <= end; val += 1.0) {
                scale.add_mark (val, Gtk.PositionType.BOTTOM, null);
            }

            scale.hexpand = true;
            scale.draw_value = false;

            set_size_request ((int)(end - start) * 20, -1);
        }

        public uint get_value () {
            return (uint)(scale.get_value ()) * step;
        }

        public void set_value (uint val) {
            scale.set_value ((double)val / (double)step);
            scale.value_changed ();
        }

    }
}
}
