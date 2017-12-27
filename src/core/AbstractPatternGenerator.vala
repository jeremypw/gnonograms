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
public abstract class AbstractPatternGenerator : GLib.Object {
    protected Rand rand_gen;
    private Dimensions _dimensions = Dimensions () { width = 0, height = 0 };
    public Dimensions dimensions {
        get {
            return _dimensions;
        }

        set {
            _dimensions = value;
            set_parameters ();
        }
    }

    public uint rows {
        get { return dimensions.rows (); }
    }

    public uint cols {
        get { return dimensions.cols (); }
    }

    private Difficulty _grade = Difficulty.EASY;
    public Difficulty grade {
        get {
            return _grade;
        }

        set {
            _grade = value;
            set_parameters ();
        }
    }

    public abstract My2DCellArray generate ();
    public virtual void harder () {}
    public virtual void easier () {}
    protected abstract void set_parameters ();

    construct {
        rand_gen = new Rand ();
    }
}
}
