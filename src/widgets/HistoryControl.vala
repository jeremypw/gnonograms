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
    private Stack<Move> back_stack;
    private Stack<Move> forward_stack;
    Gtk.Button button_back;
    Gtk.Button button_forward;

    Move? current_move;

    public signal void go_forward (Move move);
    public signal void go_back (Move move);

    construct {
        current_move = null;

        back_stack = new Stack<Move> ();
        forward_stack = new Stack<Move> ();

        button_back = new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_forward = new Gtk.Button.from_icon_name ("go-next-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_back.tooltip_text = _("Previous");
        button_back.show_all ();
        pack_start (button_back);

        button_forward.tooltip_text = _("Next");
        button_forward.show_all ();
        pack_start (button_forward);

        button_forward.clicked.connect (on_button_forward_clicked);
        button_back.clicked.connect (on_button_back_clicked);
    }

    public HistoryControl () {
        var style = get_style_context ();
        style.add_class (Gtk.STYLE_CLASS_LINKED);
        style.add_class ("raised"); // needed for toolbars
    }

    public void record_move (Cell cell, CellState previous_state) {
        var new_move = new Move (cell, previous_state);
        if (current_move != null) {
            if (new_move.cell.state != CellState.UNDEFINED) {
                if (current_move != new_move) {
                    forward_stack.clear ();
                    back_stack.push (current_move);
                }
            } else { /* If current move is not valid remember previous uri anyway so that back button works */
                back_stack.push (current_move);
            }

            current_move.copy (new_move);
        } else {
            current_move = new_move;
        }
    }

    private void on_button_forward_clicked () {
message ("Forward");
    }

    private void on_button_back_clicked () {
message ("Back");
    }

    private class Stack<G> {
        private Gee.LinkedList<G> list;

        public Stack () {
            list = new Gee.LinkedList<G> ();
        }

        public Stack<G> push (G element) {
            list.offer_head (element);
            return this;
        }

        public G pop () {
            return list.poll_head ();
        }

        public G peek () {
            return list.peek_head ();
        }

        public int size () {
            return list.size;
        }

        public void clear () {
            list.clear ();
        }

        public bool is_empty () {
            return size () == 0;
        }

        public Gee.List<G>? slice_head (int amount) {
            return list.slice (0, int.min (size (), amount));
        }
    }
} /* End: Browser class */
}


