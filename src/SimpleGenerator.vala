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
public class SimpleGenerator : AbstractGenerator {

    public SimpleGenerator (Dimensions dim, Difficulty grade) {
        Object (dimensions: dim,
                grade: grade
        );
    }

    public override CellState[] generate () {
        new_pattern ();

        var csa = new CellState[dimensions.rows () * dimensions.cols ()];
        int i = 0;

        foreach (var cell in grid) {
            csa[i++] = cell.state;
        }

        return csa;
    }

    protected override void set_parameters () {

    }

    private void new_pattern () {

    }
}
}
