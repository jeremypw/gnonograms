/*  GradeChooser.vala
 *  Copyright (C) 2010-2021  Jeremy Wootten
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
 *  Author: Jeremy Wootten <jeremywootten@gmail.com>
 */

public class Gnonograms.GradeChooser : Gtk.ComboBoxText {
    public Difficulty grade {
        get {
            return (Difficulty)(int.parse (active_id));
        }

        set {
            active_id = ((uint)value).clamp (MIN_GRADE, Difficulty.MAXIMUM).to_string ();
        }
    }

    public GradeChooser () {
        Object (
            expand: false
        );

        foreach (Difficulty d in Difficulty.all_human ()) {
            append (((uint)d).to_string (), d.to_string ());
        }
    }
}
