/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */

 public class Gnonograms.ShortcutHelper : Object {
    private Gtk.ShortcutsWindow window;

    construct {
        var builder = new Gtk.Builder.from_string (SHORTCUT_HELPER_UI, -1);
        window = (Gtk.ShortcutsWindow) builder.get_object ("shortcuts-window");
    }

    public void show_window () {
        window.present ();
    }
 }
