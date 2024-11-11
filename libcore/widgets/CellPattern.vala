/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class CellPattern : GLib.Object {
    public Cairo.Pattern pattern;
    public double width { get; construct; }
    public double height { get; construct; }
    private double red;
    private double green;
    private double blue;
    private double x0 = 0;
    private double y0 = 0;
    private Cairo.Matrix matrix;

    public CellPattern.cell (Gdk.RGBA color) {
        red = color.red;
        green = color.green;
        blue = color.blue;
        matrix = Cairo.Matrix.identity ();

        var granite_settings = Granite.Settings.get_default ();
        set_pattern (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK);

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            set_pattern (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK);
        });
    }

    public CellPattern.highlight (double wd, double ht) {
        Object (
            width: wd,
            height: ht
        );
    }

    construct {
        var r = double.min (width, height) / 2.0;
        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, (int)width , (int)height);
        var context = new Cairo.Context (surface);
        context.set_source_rgb (0.0, 0.0, 0.0);
        context.rectangle (0, 0, width, height);
        context.fill ();
        context.arc (width / 2.0, height / 2.0, r - 2.0, 0, 2 * Math.PI);
        context.set_source_rgba (1.0, 1.0, 1.0, 0.5);
        context.set_operator (Cairo.Operator.SOURCE);
        context.fill ();

        pattern = new Cairo.Pattern.for_surface (surface);
        pattern.set_extend (Cairo.Extend.NONE);
        matrix = Cairo.Matrix.identity ();
        pattern.set_matrix (matrix);
    }

    public void move_to (double x, double y) {
        var xx = x - x0;
        var yy = y - y0;
        matrix.translate (-xx, -yy);
        pattern.set_matrix (matrix);
        x0 = x;
        y0 = y;
    }

    private void set_pattern (bool is_dark) {
        pattern = new Cairo.Pattern.rgba (
            is_dark ? red / 2 : red,
            is_dark ? green / 2 : green,
            is_dark ? blue / 2 : blue,
            1.0
        );
    }
}
