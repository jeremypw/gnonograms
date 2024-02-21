/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.History : GLib.Object {
    public bool can_go_back { get; private set; }
    public bool can_go_forward { get; private set; }

    private HistoryStack back_stack;
    private HistoryStack forward_stack;

    construct {
        back_stack = new HistoryStack ();
        forward_stack = new HistoryStack ();

        back_stack.notify["empty"].connect (() => {
            can_go_back = !back_stack.empty;
        });

        forward_stack.notify["empty"].connect (() => {
            can_go_forward = !forward_stack.empty;
        });
    }

    public void clear_all () {
        forward_stack.clear ();
        back_stack.clear ();
    }

    public void record_move (Cell cell, CellState previous_state) {
        var new_move = new Gnonograms.Move (cell, previous_state);
        if (new_move.cell.state != CellState.UNDEFINED) {
            Move last_move = back_stack.peek_move ();
            if (last_move.equal (new_move)) {
                return;
            }

            forward_stack.clear ();
        }

        back_stack.push_move (new_move);
    }

    public Move pop_next_move () {
        Move mv = forward_stack.pop_move ();
        back_stack.push_move (mv);
        return mv;
    }

    public Move pop_previous_move () {
        Move mv = back_stack.pop_move ();
        /* Record copy otherwise it will be altered by next line*/
        forward_stack.push_move (mv.clone ());
        mv.cell.state = mv.previous_state;
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

    private void add_to_stack_from_string (string? s, bool back) {
        if (s == null) {
            return;
        }

        var moves_s = s.split (";");
        if (moves_s == null) {
            return;
        }

        foreach (string move_s in moves_s) {
            var move = Move.from_string (move_s);
            if (move != null) {
                if (back) {
                    back_stack.push_move (move);
                } else {
                    forward_stack.push_move (move);
                }
            }
        }
    }

    private class HistoryStack : Object {
        public bool empty { get; private set; }

        private Gee.Deque<Move> stack;

        construct {
            stack = new Gee.LinkedList<Move> ();
        }

        public void push_move (Move mv) {
            if (!mv.is_null ()) {
                stack.offer_head (mv);
                empty = false;
            }
        }

        public Move peek_move () {
            if (empty) {
                return Move.null_move;
            } else {
                return stack.peek_head ();
            }
        }

        public Move pop_move () {
            Move mv = Move.null_move;
            if (!empty) {
                mv = stack.poll_head ();
            }

            empty = stack.is_empty;
            return mv;
        }

        public void clear () {
            stack.clear ();
            empty = true;
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
}
