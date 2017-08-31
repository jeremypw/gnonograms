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
public enum Difficulty {
    TRIVIAL = 0,
    EASY = 2,
    MODERATE = 3,
    HARD =4 ,
    CHALLENGING = 5,
    ADVANCED = 6,
    MAXIMUM = 7,
    UNDEFINED = 99;
}

public static string difficulty_to_string (Difficulty d) {
    switch (d) {
        case Difficulty.TRIVIAL:
            return _("Very Easy");
        case Difficulty.EASY:
            return _("Easy");
        case Difficulty.MODERATE:
            return _("Moderately difficult");
        case Difficulty.HARD:
            return _("Difficult");
        case Difficulty.CHALLENGING:
            return _("Very Difficult");
        case Difficulty.ADVANCED:
            return _("Advanced logic required");
        default:
            return _("Possibly ambiguous");
    }
}

public enum GameState {
    SETTING,
    SOLVING,
    UNDEFINED;
}

public enum CellState {
    UNKNOWN,
    EMPTY,
    FILLED,
    ERROR,
    COMPLETED,
    ERROR_EMPTY,
    ERROR_FILLED,
    UNDEFINED;
}

public enum CellPatternType {
    CELL,
    HIGHLIGHT,
    UNDEFINED
}

public enum ButtonPress {
    LEFT_SINGLE,
    LEFT_DOUBLE,
    MIDDLE_SINGLE,
    MIDDLE_DOUBLE,
    RIGHT_SINGLE,
    RIGHT_DOUBLE,
    UNDEFINED
}

public enum FileChooserAction {
    OPEN,
    SAVE_NO_SOLUTION,
    SAVE_WITH_SOLUTION,
    SELECT_FOLDER,
    UNDEFINED
}
}
