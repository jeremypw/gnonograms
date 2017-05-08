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

class AppMenu : Gtk.Button {
    private const uint STEP = 5;
    private AppPopover popover;
    private AppScale rows_scale;
    private uint _row_val;
    public uint row_val {
        get {
            return _row_val;
        }

        set {
            _row_val = value;
            rows_scale.set_value (_row_val);
        }
    }
    private AppScale cols_scale;
    private uint _col_val;
    public uint col_val {
        get {
            return _col_val;
        }

        set {
            _col_val = value;
            cols_scale.set_value (_col_val);
        }
    }

    private AppScale grade_scale;
    private uint _grade_val;
    public uint grade_val {
        get {
            return _grade_val;
        }

        set {
            _grade_val = value;
            grade_scale.set_value (value);
        }
    }

    public signal void apply ();

    construct {
        popover = new AppPopover (this);
        var grid = new Gtk.Grid ();
        popover.add (grid);
        popover.set_size_request (200, -1);

        rows_scale = new AppScale (STEP, MAXSIZE, STEP);
        cols_scale = new AppScale (STEP, MAXSIZE, STEP);
        grade_scale = new AppScale (1, MAXGRADE, 1);

        var row_label = new Gtk.Label (_("Rows"));
        var col_label = new Gtk.Label (_("Columns"));
        var grade_label = new Gtk.Label (_("Difficulty"));

        row_label.xalign = 1;
        col_label.xalign = 1;
        grade_label.xalign = 1;

        grid.attach (row_label, 0, 0, 1, 1);
        grid.attach (col_label, 0, 1, 1, 1);
        grid.attach (grade_label, 0, 2, 1, 1);
        grid.attach (rows_scale, 1, 0, 1, 1);
        grid.attach (cols_scale, 1, 1, 1, 1);
        grid.attach (grade_scale, 1, 2, 1, 1);

        grid.row_spacing = 12;
        grid.column_spacing = 6;
        grid.border_width = 12;

        clicked.connect (() => {
            store_values ();
            popover.show_all ();
        });

        popover.apply_settings.connect (() => {
            store_values ();
            apply ();
        });

        popover.cancel.connect (() => {
            restore_values ();
        });
    }

    public AppMenu (Dimensions dimensions, uint grade) {
        image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        tooltip_text = _("Options");
        row_val = dimensions.height;
        col_val = dimensions.width;
        grade_val = grade;
    }

    private void store_values () {
        row_val = rows_scale.get_value ();
        col_val = cols_scale.get_value ();
        grade_val = grade_scale.get_value ();
    }

    private void restore_values () {
        rows_scale.set_value (row_val);
        cols_scale.set_value (col_val);
        grade_scale.set_value (grade_val);
    }

    /** Popover that can be cancelled with Escape and closed by Enter **/
    private class AppPopover : Gtk.Popover {
        private bool cancelled = false;
        public signal void apply_settings ();
        public signal void cancel ();


        construct {
            show.connect (() => {
                store_values ();
            });

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

        private void store_values () {

        }
    }

    /** Scale limited to integral values separated by step (interface uses uint) **/
    private class AppScale : Gtk.Grid {
        private uint step;
        private Gtk.HScale scale;
        private Gtk.Label val_label;

        construct {
            scale = new Gtk.HScale (null);
            val_label = new Gtk.Label (null);
            attach (val_label, 0, 0, 1, 1);
            attach (scale, 1, 0, 1, 1);

            scale.value_changed.connect (() => {
                val_label.label = get_value ().to_string ();
            });
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
        }

        public uint get_value () {
            return (uint)(scale.get_value ()) * step;
        }

        public void set_value (uint val) {
            scale.set_value ((double)val / (double)step);
        }

    }
}
}
