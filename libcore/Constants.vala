/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
namespace Gnonograms {
    public const Cell NULL_CELL = { uint.MAX, uint.MAX, CellState.UNDEFINED };
    public const uint MAXSIZE = 54; // max number rows or columns
    public const uint MINSIZE = 5; // Change to 1 when debugging
    public const uint SIZESTEP = 5; // Change to 1 when debugging
    public const double GRID_LABELBOX_RATIO = 0.3; // For simplicity give labelboxes fixed ratio of cellgrid dimension
    public const Difficulty MIN_GRADE = Difficulty.EASY; /* TRIVIAL and VERY EASY GRADES not worth supporting */
    public const string BLOCKSEPARATOR = ", ";
    public const string BLANKLABELTEXT = N_("?");
    public const string GAMEFILEEXTENSION = ".gno";
    public const string UNSAVED_FILENAME = "Unsaved Game" + GAMEFILEEXTENSION;
    public const string UNTITLED_NAME = N_("Untitled");
    public const string APP_NAME = "Gnonograms";
    public const string SETTING_FILLED_COLOR = "#000000"; /* Elementary Black 900 */
    public const string SETTING_EMPTY_COLOR = "#fafafa"; /* Elementary Silver 100 */
    public const string SOLVING_FILLED_COLOR = "#180297"; /* Gnonograms Dark Purple */
    public const string SOLVING_EMPTY_COLOR = "#ffff00"; /* Pure Yellow */
    public const string UNKNOWN_COLOR = "#d4d4d4"; /* Elementary Silver 300 */
    public const string GRID_COLOR = "#000000"; /* Elementary Black 900 */
}
