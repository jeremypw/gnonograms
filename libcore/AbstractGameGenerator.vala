/* Handles working and solution data for gnonograms
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
public abstract class AbstractGameGenerator : GLib.Object {
    protected AbstractPatternGenerator pattern_gen;
    protected AbstractSolver solver;

    protected bool cancelled {
        get {
            return solver.cancelled;
        }
    }

    protected Dimensions dimensions {
        get {
            return pattern_gen.dimensions;
        }
    }

    public Difficulty grade {
        get {
            return pattern_gen.grade;
        }

        set {
            pattern_gen.grade = value;
            solver.configure_from_grade (value);
        }
    }

    public Difficulty solution_grade { get; protected set; default = Difficulty.UNDEFINED; }
    public void cancel () {
        solver.cancel ();
    }

    public abstract bool generate ();
    public abstract My2DCellArray get_solution ();
}
}
