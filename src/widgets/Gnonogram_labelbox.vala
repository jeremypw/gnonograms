/* Holds all row or column clues for gnonograms-elementary
 * Copyright (C) display_working  Jeremy Wootten
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

public class LabelBox : Gtk.Box {
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

    private uint size { /* no of labels in box */
        get {
            return vertical_labels ? dimensions.width : dimensions.height;
        }
    }

    private uint other_size { /* size of other label box */
        get {
            return vertical_labels ? dimensions.height : dimensions.width;
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

    private bool vertical_labels; /* true if contains column labels(i.e. HBox) */

    public LabelBox (Gtk.Orientation orientation, Dimensions dimensions) {
        Object (orientation: orientation,
                homogeneous: true,
                spacing: 0);

        vertical_labels = orientation == Gtk.Orientation.HORIZONTAL;
        this.dimensions = dimensions; /* Cannot set this in object */
    }

    public void resize () {
        unhighlight_all();

        GLib.List<weak Gtk.Widget> children = get_children ();
        var current_size = children.length ();
        uint current_other_size;

        if (current_size > 0) {
            current_other_size = ((Label)(children.first ().data)).size;
        } else {
            current_other_size = other_size;
        }

        if (current_other_size != other_size) {
            update_label_size ();
        }

        while (current_size < size) {
            var label = new Label (vertical_labels);
            label.size = other_size;
            add (label);

            current_size++;
        }

        while (current_size > size) {
            remove (children.last ().data);
            current_size--;
        }
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
            txt = BLANKLABELTEXT;
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

    public void update_label (int idx, string? txt) {
        if (txt == null) {
            txt = BLANKLABELTEXT;
        }

        var label = (Label)(get_children ().nth_data ((uint)idx));
        label.clue = txt;
    }
}
}
