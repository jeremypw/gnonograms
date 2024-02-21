/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms {
    public enum Difficulty {
        TRIVIAL = 0,
        VERY_EASY = 1,
        EASY = 2,
        MODERATE = 3,
        HARD = 4 ,
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
                    return "";
                default:
                    critical ("grade to string - unexpected grade");
                    assert_not_reached ();
            }
        }

        public static string[] all_human () {
            return {
                EASY.to_string (),
                MODERATE.to_string (),
                HARD.to_string (),
                CHALLENGING.to_string (),
                ADVANCED.to_string (),
                MAXIMUM.to_string ()
            };
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
}
