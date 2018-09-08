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

public class Gnonograms.SettingSwitch : Gnonograms.AppSetting {
    public Gtk.Switch @switch { get; construct; }
    public Gtk.Label label { get; construct; }

    construct {
        @switch = new Gtk.Switch ();
        @switch.halign = Gtk.Align.START;
        @switch.hexpand = false;
        @switch.state = false;
    }

    public SettingSwitch (string heading) {
        Object (
            label: new Gtk.Label (heading)
        );
    }

    public override Gtk.Label get_heading () {return label;}
    public override Gtk.Widget get_chooser () {return @switch;}

    public override bool get_state () {return @switch.state;}
    public override void set_state (bool state) {@switch.state = state;}

}
