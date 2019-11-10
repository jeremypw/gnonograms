/* Copyright (C) 2010-2017  Jeremy Wootten
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

/** Setting Widget using a Scale limited to integral values separated by step **/
public class Gnonograms.ScaleGrid : Gnonograms.AppSetting {
    public string heading { get; set; }
    private Gtk.Grid chooser { get; set; }
    private Gtk.Label heading_label { get; set; }
    private Gtk.Label val_label;
    private Gtk.Scale scale;
    private uint _value = 0;
    public override uint @value {
        get {
            return _value;
        }

        set {
            if (value < Gnonograms.MINSIZE ||
                value > Gnonograms.MAXSIZE) {
                return;
            }

            var scale_val = Math.floor (value / Gnonograms.SIZESTEP);
            scale.set_value (scale_val);
            val_label.label = value.to_string ();
            _value = value;
            value_changed (value);
        }
    }

    public signal void value_changed (uint @value);

    construct {
        val_label = new Gtk.Label ("");
        val_label.halign = Gtk.Align.END;
        val_label.set_size_request (32, -1);
        chooser = new Gtk.Grid ();
        chooser.column_spacing = 3;
        chooser.attach (val_label, 1, 0, 1, 1);


        var step = (double)Gnonograms.SIZESTEP;
        var start = (double)Gnonograms.MINSIZE / step;
        var end = (double)Gnonograms.MAXSIZE / step;
        var adj = new Gtk.Adjustment (start, start, end, 0.1, 1.0, 1.0);

        scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adj);
        scale.can_focus = false;
        scale.halign = Gtk.Align.START;
        scale.valign = Gtk.Align.START;
        scale.expand = false;
        scale.hexpand = true;
        scale.hexpand_set = true;
        scale.draw_value = false;
        scale.set_size_request ((int)(end - start + 1) * 24, -1);

        for (var val = start; val < end; val += 1.0) {
            scale.add_mark (val, Gtk.PositionType.BOTTOM, null);
        }

        chooser.attach (scale, 0, 0, 1, 1);

        /* Connecting to scale.value_changed does not work as library dependency */
        adj.notify["value"].connect (() => {
            var scale_val = adj.@value;
            var round_val = (uint)(scale_val + 0.5); // Round to nearest 1.0
            uint val = round_val * Gnonograms.SIZESTEP;
            @value = val;
        });
    }

    public ScaleGrid (string _heading) {
        Object (heading: _heading);

        heading_label = new Gtk.Label (heading);
    }

    public override Gtk.Label get_heading () {
        return heading_label;
    }

    public override Gtk.Widget get_chooser () {
        return chooser;
    }
}
