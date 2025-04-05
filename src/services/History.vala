/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.History : GLib.Object {
    private class HistoryStack : Object {
        public bool empty {
            get {
                return stack.is_empty;
            }
        }

        private Gee.Deque<Move> stack;

        construct {
            stack = new Gee.LinkedList<Move> ();
        }

        public void push_move (Move mv) requires (mv.is_valid ()) {
            stack.offer_head (mv);
        }

        public Move? peek_move () {
            return stack.peek_head ();
        }

        public Move? pop_move () {
            return stack.poll_head ();
        }

        public void clear () {
            stack.clear ();
        }

        public string to_string () {
            var sb = new StringBuilder ("");
            foreach (Move mv in stack) { /* iterates from head backwards */
                sb.prepend (mv.to_string () + ";");
            }

            sb.append ("\n");
            return sb.str;
        }
    }

    public bool can_go_back {
        get {
            return !back_stack.empty;
        }
    }

    public bool can_go_forward {
        get {
            return !forward_stack.empty;
        }
    }

    private HistoryStack back_stack;
    private HistoryStack forward_stack;

    public signal void can_go_changed (bool forward, bool back);

    construct {
        back_stack = new HistoryStack ();
        forward_stack = new HistoryStack ();
    }

    private void signal_can_go_changed () {
        can_go_changed (!forward_stack.empty, !back_stack.empty );
    }

    public void clear_all () {
        forward_stack.clear ();
        back_stack.clear ();
        signal_can_go_changed ();
    }

    public void record_move (Cell? cell, CellState previous_state) {
        if (cell == null) {
            return;
        }

        var new_move = new Gnonograms.Move.from_cell (cell, previous_state);
        Move? last_move = back_stack.peek_move ();
        if (new_move.equal (last_move)) {
            return;
        }

        forward_stack.clear ();

        back_stack.push_move (new_move);
        signal_can_go_changed ();
    }

    public Move pop_next_move () {
        Move mv = forward_stack.pop_move ();
        back_stack.push_move (mv);
        signal_can_go_changed ();
        return mv;
    }

    public Move pop_previous_move () {
        Move mv = back_stack.pop_move ();
        /* Record copy otherwise it will be altered by next line*/
        forward_stack.push_move (mv.clone ());
        mv.cell.state = mv.previous_state;
        signal_can_go_changed ();
        return mv;
    }

    public Move? get_current_move () {
        return back_stack.peek_move ();
    }

    public string to_string () {
        return back_stack.to_string () + forward_stack.to_string ();
    }

    public void from_string (string? s) {
        clear_all ();
        if (s == null) {
            return;
        }

        var stacks = Utils.remove_blank_lines (s.split ("\n"));
        if (stacks != null) {
            add_to_stack_from_string (stacks[0], true);
        }

        if (stacks.length > 1) {
            add_to_stack_from_string (stacks[1], false);
        }
    }

    private bool add_to_stack_from_string (string? s, bool back) {
        if (s == null) {
            return false;
        }

        var moves_s = s.split (";");
        if (moves_s == null) {
            return false;
        }

        foreach (string move_s in moves_s) {
            try {
                var move = Move.from_string (move_s);
                if (move != null) {
                    if (back) {
                        back_stack.push_move (move);
                    } else {
                        forward_stack.push_move (move);
                    }
                }
            } catch (Error e) {
                warning ("Could not convert %s to Move.  %s", move_s, e.message);
                return false;
            }
        }

        signal_can_go_changed ();
        return true;
    }
}
