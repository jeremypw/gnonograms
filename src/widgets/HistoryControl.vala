/* UI for move history for gnonograms-elementary
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
 *
 *  Adapted from Marlin.View.Browser Author: ammonkey <am.monkeyd@gmail.com>
 */

namespace Gnonograms {

class HistoryControl : Gtk.Box {
    private Gee.Deque<Move> back_stack;
    private Gee.Deque<Move> forward_stack;
    Gtk.Button button_back;
    Gtk.Button button_forward;

    public signal void go_forward (Move move);
    public signal void go_back (Move move);

    construct {
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();

        button_back = new HistoryButton ("go-previous-symbolic", Gtk.IconSize.LARGE_TOOLBAR, _("Previous"));
        button_forward = new HistoryButton ("go-next-symbolic", Gtk.IconSize.LARGE_TOOLBAR, _("Next"));

        pack_start (button_back);
        pack_start (button_forward);

        button_forward.clicked.connect (on_button_forward_clicked);
        button_back.clicked.connect (on_button_back_clicked);
    }

    public void record_move (Cell cell, CellState previous_state) {
        var new_move = new Move (cell, previous_state);

        if (new_move.cell.state != CellState.UNDEFINED) {
            Move? current_move = back_stack.peek_head ();
            if (current_move != null && current_move.equal (new_move)) {
                return;
            }

            forward_stack.clear ();
            button_forward.sensitive = false;
        }

        back_stack.offer_head (new_move);
        button_back.sensitive = true;
    }

    private void on_button_back_clicked () {
        if (back_stack.size > 0) {
            Move mv = back_stack.poll_head ();
            forward_stack.offer_head (mv);
            go_back (mv);
        }

        button_back.sensitive = !back_stack.is_empty;
        button_forward.sensitive = !forward_stack.is_empty;
    }

    private void on_button_forward_clicked () {
        if (forward_stack.size > 0) {
            Move mv = forward_stack.poll_head ();
            back_stack.offer_head (mv);
            go_forward (mv);
        }

        button_back.sensitive = back_stack.size > 0;
        button_forward.sensitive = forward_stack.size > 0;
    }

    private class HistoryButton : Gtk.Button {
        public HistoryButton (string icon_name,  Gtk.IconSize icon_size, string tip) {
            Object (image: new Gtk.Image.from_icon_name (icon_name, icon_size));

            tooltip_text = tip;
            show_all ();
            sensitive = false;
        }

    }
}
}


