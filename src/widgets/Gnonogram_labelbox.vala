/* Label box class for Gnonograms3
 * Copyright (C) 2010-2011  Jeremy Wootten
 *
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */

namespace Gnonograms {

public class LabelBox : Gtk.Box {
    private bool is_column; /* true if contains column labels(i.e. HBox) */

    private Dimensions _dimensions;
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            _dimensions = value;
            resize();
        }
    }

    private int size { /* no of labels in box */
        get {
            return is_column ? dimensions.height : dimensions.width;
        }
    }

    private int othersize { /* size of other label box */
        get {
            return is_column ? dimensions.width : dimensions.height;
        }
    }

    private double _fontheight;
    public double fontheight {
        get {
            return _fontheight;
        }

        set {
            _fontheight = value.clamp(Gnonograms.MINFONTSIZE, Gnonograms.MAXFONTSIZE);

            foreach (Gtk.Widget l in get_children ()) {
                ((Label)l).fontheight = _fontheight;
            }
        }
    }

    public LabelBox (Gtk.Orientation orientation, Dimensions dimensions) {
        Object (orientation: orientation,
                spacing: 0);

        is_column = (orientation == Gtk.Orientation.HORIZONTAL);
        set_homogeneous (true);

        this.dimensions = dimensions;
        set_all_to_string ("1,4,2,1");
        fontheight = 24.0;
        show_all ();
    }

    public void resize () {
        unhighlight_all();

        GLib.List<weak Gtk.Widget> children = get_children ();
        var current_size = children.length ();
        int current_other_size;

        if (current_size > 0) {
            current_other_size = ((Label)(children.first ().data)).size;
        } else {
            current_other_size = othersize;
        }

        if (current_other_size != othersize) {
            update_label_size ();
        }

        while (current_size < size) {
            var label = new Label ("0", is_column);
            label.size = othersize;
            add (label);

            current_size++;
        }
        while (current_size > size) {
            remove (children.last ().data);
            current_size--;
        }

        fontheight = fontheight;
        show_all ();
    }

    public void change_font_height(bool increase) {
        if (increase) {
            fontheight += 1.0;
        } else {
            fontheight -= 1.0;
        }
    }

    public void highlight (uint idx, bool is_highlight) {
        if (idx >= size) {
            return;
        }

        ((Label)get_children ().nth_data (idx)).highlight (is_highlight);
    }

    private void unhighlight_all() {
        foreach (Gtk.Widget l in get_children ()) {
            ((Label)l).highlight (false);
        }
    }

    public void update_label_txt (int idx, string? txt) {
        if (txt == null) {
            txt = "?";
        }

        ((Label)(get_children ().nth_data (idx))).clue = txt;
    }

    public void update_label_size () {
        foreach (Gtk.Widget l in get_children ()) {
            ((Label)l).size = size;
        }
    }

    public string to_string() {
        StringBuilder sb=new StringBuilder();

        foreach (Gtk.Widget l in get_children ()) {
            sb.append (((Label)l).label);
            sb.append ("\n");
        }

        return sb.str;
    }

    public void set_all_to_string (string txt) {
        foreach (Gtk.Widget l in get_children ()) {
            ((Label)l).clue = txt;
        }
    }
}
}
