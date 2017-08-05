
/* Entry point for gnonograms-elementary  - initialises application and launches game
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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {
    public const Cell NULL_CELL = { uint.MAX, uint.MAX, CellState.UNDEFINED };
    public static int MAXSIZE = 50; // max number rows or columns
    public static int MINSIZE = 5; // Change to 1 when debugging
    public static double MINFONTSIZE = 3.0;
    public static double MAXFONTSIZE = 72.0;
    public static int FAILED_PASSES = 999999;
    public const string BLOCKSEPARATOR = ", ";
    public const string BLANKLABELTEXT = _("?");
    public const string GAMEFILEEXTENSION = ".gno";
    public const string UNSAVED_FILENAME = "Unsaved Game" + GAMEFILEEXTENSION;
}
