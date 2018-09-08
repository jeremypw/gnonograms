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
    public Gtk.Grid chooser { get; set; }
    public Gtk.Label heading_label { get; set; }
    private Gtk.Label val_label;
    private Gtk.Scale scale;
    private Gtk.Adjustment adj;

    public signal void value_changed (uint @value);

    construct {
        val_label = new Gtk.Label ("");
        chooser = new Gtk.Grid ();
        chooser.column_spacing = 6;
    }

    public ScaleGrid (string _heading) {
        Object (heading: _heading);
        var step = (double)Gnonograms.SIZESTEP;
        var start = (double)Gnonograms.MINSIZE / step;
        var end = (double)Gnonograms.MAXSIZE / step + 1.0;
        adj = new Gtk.Adjustment (start, start, end, 1.0, 1.0, 1.0);
        scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adj);
        scale.can_focus = false;
        scale.expand = false;
        scale.hexpand = true;
        scale.draw_value = false;
        scale.set_size_request ((int)(end - start) * 20, -1);
        scale.valign = Gtk.Align.START;

        for (var val = start; val <= end; val += 1.0) {
            scale.add_mark (val, Gtk.PositionType.BOTTOM, null);
        }

        /* Connecting to scale.value_changed does not work as library dependency */
        adj.notify["value"].connect (() => {
            var scale_val = adj.@value;
            var round_val = (uint)(scale_val + 0.1);
            var val = round_val * Gnonograms.SIZESTEP;
            val_label.label = val.to_string ();
            value_changed (val);

            if ((double)round_val != scale_val) {
                set_value (val);
            }
        });

        heading_label = new Gtk.Label (heading);
        val_label.xalign = 0;

        chooser.attach (scale, 0, 0, 1, 1);
        chooser.attach (val_label, 1, 0, 1, 1);
    }

    public override void set_value (uint val) {
        if (val < Gnonograms.MINSIZE || val > Gnonograms.MAXSIZE) {
            return;
        }

        var scale_val = (double)(val / Gnonograms.SIZESTEP);
        if ((uint)(adj.@value) * Gnonograms.SIZESTEP  == val) {
            value_changed (val);
        }
        scale.set_value (scale_val);
        val_label.label = val.to_string ();
    }

    public override uint get_value () {
        return (uint)(scale.get_value () * Gnonograms.SIZESTEP);
    }

    public override Gtk.Label get_heading () {
        return heading_label;
    }

    public override Gtk.Widget get_chooser () {
        return chooser;
    }
}
