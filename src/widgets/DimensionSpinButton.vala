/* Copyright (C) 2021  Jeremy Wootten
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

public class Gnonograms.DimensionSpinButton : Gtk.SpinButton {
    public DimensionSpinButton () {
        Object (
            adjustment: new Gtk.Adjustment (5.0, 5.0, 50.0, 5.0, 5.0, 5.0),
            climb_rate: 5.0,
            digits: 0,
            snap_to_ticks: true,
            orientation: Gtk.Orientation.HORIZONTAL,
            margin_top: 3,
            margin_bottom: 3,
            width_chars: 3,
            can_focus: false
        );
    }
}
