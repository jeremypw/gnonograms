/* Handles working and solution data for gnonograms-elementary
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
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms {
public class AdvancedRandomGameGenerator : SimpleRandomGameGenerator {
    public AdvancedRandomGameGenerator (Dimensions dimensions, Difficulty grade, GamePatternType pattern, Cancellable? _cancellable) {
        base (dimensions, grade, pattern, _cancellable);
        use_advanced = true;
    }

    public override async bool generate () {
        /* returns true if a game of correct grade was generated otherwise false  */
        return yield base.generate ();
    }

}
}
