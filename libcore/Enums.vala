/* Entry point for gnonograms  - initializes application and launches game
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
public enum Difficulty {
    TRIVIAL = 0,
    VERY_EASY = 1,
    EASY = 2,
    MODERATE = 3,
    HARD =4 ,
    CHALLENGING = 5,
    ADVANCED = 6,
    MAXIMUM = 7, /* Max grade for generated puzzles (possibly ambiguous)*/
    COMPUTER = 8, /* Grade for requested computer solving */
    UNDEFINED = 99;

    public string to_string () {
        switch (this) {
            case Difficulty.TRIVIAL:
                return _("Trivial");
            case Difficulty.VERY_EASY:
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
            case Difficulty.MAXIMUM:
                return _("Possibly ambiguous");
            case Difficulty.COMPUTER:
                return _("Super human");
            case Difficulty.UNDEFINED:
                return _("Undefined");
            default:
                critical ("grade to string - unexpected grade");
                assert_not_reached ();
        }
    }

    public static Difficulty[] all_human () {
        return { EASY, MODERATE, HARD, CHALLENGING, ADVANCED, MAXIMUM };
    }
}

public enum GameState {
    SETTING,
    SOLVING,
    GENERATING,
    UNDEFINED = 99;
}

public enum CellState {
    UNKNOWN,
    EMPTY,
    FILLED,
    COMPLETED,
    UNDEFINED;
}

public enum SolverState {
    ERROR = 0,
    CANCELLED = 1,
    NO_SOLUTION = 1 << 1,
    SIMPLE = 1 << 2,
    ADVANCED = 1 << 3,
    AMBIGUOUS = 1 << 4,
    UNDEFINED = 1 << 5;

    public bool solved () {
        return this == SIMPLE || this == ADVANCED || this == AMBIGUOUS;
    }
}

public enum CellPatternType {
    CELL,
    HIGHLIGHT,
    UNDEFINED
}

public enum GamePatternType {
    SIMPLE_RANDOM,
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
