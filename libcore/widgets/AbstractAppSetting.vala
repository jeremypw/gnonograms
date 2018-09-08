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

public abstract class Gnonograms.AppSetting : Object {
    public virtual void set_value (uint val) {return;}
    public virtual uint get_value () {return 0;}
    public virtual void set_state (bool active) {return;}
    public virtual bool get_state () {return false;}
    public virtual void set_text (string text) {}
    public virtual unowned string get_text () {return "";}
    public abstract Gtk.Label get_heading ();
    public abstract Gtk.Widget get_chooser ();
}
