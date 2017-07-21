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
    private AppScale row_scale;
    private Gtk.Label row_label;
    private AppScale column_scale;
    private Gtk.Label column_label;

    private uint _grade_val;
    public uint grade_val {
        get {
            return _grade_val;
        }

        set {
            _grade_val = value;
            grade_scale.set_value (value);
            grade_label.label = Gnonograms.difficulty_to_string ((Difficulty)(grade_scale.get_value ()));
        }
    }

    private uint _row_val;
    public uint row_val {
        get {
            return _row_val;
        }

        set {
            _row_val = value;
            row_scale.set_value (value);
            row_label.label = row_scale.get_value ().to_string ();
        }
    }

    private uint _column_val;
    public uint column_val {
        get {
            return _column_val;
        }

        set {
            _column_val = value;
            column_scale.set_value (value);
            column_label.label = column_scale.get_value ().to_string ();
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
            var val = grade_scale.get_value ();

            var s = Gnonograms.difficulty_to_string ((Difficulty)(val));
            if (s != grade_label.label) {
                grade_label.label = s;
            }
        });

        grade_label = new Gtk.Label ("");
        var grade_grid = new ScaleGrid (_("Grade"), grade_label, grade_scale);

        row_scale = new AppScale (5, 50, 5);
        row_scale.scale.value_changed.connect ((range) => {
            var val = row_scale.get_value ();
            var s = val.to_string ();
            if (s != row_label.label) {
                row_label.label = s;
            }
        });

        row_label = new Gtk.Label ("");
        var row_grid = new ScaleGrid (_("Rows"), row_label, row_scale);

        column_scale = new AppScale (5, 50, 5);
        column_scale.scale.value_changed.connect ((range) => {
            var val = column_scale.get_value ();
            var s = val.to_string ();
            if (s != column_label.label) {
                column_label.label = s;
            }
        });
        column_label = new Gtk.Label ("");
        var column_grid = new ScaleGrid (_("Columns"), column_label, column_scale);

        grid.attach (grade_grid, 0, 0, 1, 1);
        grid.attach (row_grid, 0, 1, 1, 1);
        grid.attach (column_grid, 0, 2, 1, 1);
        grid.row_homogeneous = true;
        grid.set_size_request (200, -1);

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
        row_val = (uint)(row_scale.get_value ());
        column_val = (uint)(column_scale.get_value ());
    }

    private void restore_values () {
        grade_scale.set_value (grade_val);
        row_scale.set_value (row_val);
        column_scale.set_value (column_val);
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
    protected class AppScale : Gtk.Grid {
        private uint step;
        public Gtk.Scale scale {get; private set;}
        private Gtk.Label val_label;

        construct {
            scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, null);
            val_label = new Gtk.Label (null);
            val_label.xalign = 1;

            attach (val_label, 0, 0, 1, 1);
            attach (scale, 1, 0, 1, 1);
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

    protected class ScaleGrid : Gtk.Grid {

        public string heading {get; set;}
        public Gtk.Label val_label {get; set;}
        public AppScale scale {get; set;}

        construct {
            margin = 12;
            row_homogeneous = true;
            column_homogeneous = true;
            expand = false;
            column_spacing = 12;
        }

        public ScaleGrid (string _heading, Gtk.Label _val_label, AppScale _scale) {
            Object (heading: _heading,
                    val_label: _val_label,
                    scale: _scale);

            var heading_label = new Gtk.Label (heading);
            heading_label.use_markup = true;
            heading_label.xalign = 0.5f;
            heading_label.valign = Gtk.Align.END;
            /* So size does not change depending on text, Not ideal as max width may depend on translation */
            heading_label.set_size_request (120, -1);
            attach (heading_label, 0, 0, 1, 1);

            ((Gtk.Widget)scale).valign = Gtk.Align.START;
            attach (scale, 0, 1, 1, 3);
            val_label.xalign = 0;
            val_label.valign = Gtk.Align.START;
            attach (val_label, 1, 1, 1, 3);
        }
    }
}
}
