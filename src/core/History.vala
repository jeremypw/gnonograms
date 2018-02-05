
/*
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

/* Move class records the current cell coordinates, its state and previous state */
public class History : GLib.Object {

    private Gee.Deque<Move> back_stack;
    private Gee.Deque<Move> forward_stack;

    public bool can_go_back {
        get {
            return back_stack.size > 0;
        }
    }

    public bool can_go_forward {
        get {
            return forward_stack.size > 0;
        }
    }

    construct {
        back_stack = new Gee.LinkedList<Move> ();
        forward_stack = new Gee.LinkedList<Move> ();
    }

    public void clear_all () {
        forward_stack.clear ();
        back_stack.clear ();
    }

    public void record_move (Cell cell, CellState previous_state) {
        var new_move = new Gnonograms.Move (cell, previous_state);

        if (new_move.cell.state != CellState.UNDEFINED) {
            Move? current_move = back_stack.peek_head ();
            if (current_move != null && current_move.equal (new_move)) {
                return;
            }

            forward_stack.clear ();
        }

        back_stack.offer_head (new_move);
    }

    public Move pop_next_move () {
        Move mv = forward_stack.poll_head ();
        back_stack.offer_head (mv);

        return mv;
    }

    public Move pop_previous_move () {
        Move mv = back_stack.poll_head ();
        /* Record copy otherwise it will be altered by next line*/
        forward_stack.offer_head (mv.clone ());
        mv.cell.state = mv.previous_state;

        return mv;
    }
}
}
