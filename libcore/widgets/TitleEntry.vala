/* Copyright (C) 2010-2018  Jeremy Wootten
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

protected class Gnonograms.TitleEntry : Gnonograms.AppSetting {
    Gtk.Entry entry;
    Gtk.Label heading;

    construct {
        entry = new Gtk.Entry ();
        entry.placeholder_text = _("Enter title of game here");
        heading = new Gtk.Label (_("Title"));
    }

    public override Gtk.Label get_heading () {return heading;}

    public override Gtk.Widget get_chooser () {return entry;}

    public override unowned string get_text () {return entry.text;}
    public override void set_text (string text) {
        entry.text = text;
    }
}
