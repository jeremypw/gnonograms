/* Gnonogram permutor class for Gnonograms3
 * generates all possible solutions for a given clue.
 * Copyright (C) 2010-2011  Jeremy Wootten
 *
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */

namespace Gnonograms {
public class Permutor {
    public CellState[] perm;
    public bool valid = false;

    private int _freedom;
    private int n_blocks;
    private int[] blocks;
    private int size;
    private int[] range_start; // earliest possible start point for block
    private int[] range_end; // latest possible start point for block
    private int[] block_start; //current start point for block

    public Gnonogram_permutor (int size, string clue) {
        this.size = size;
        this.blocks = Utils.block_array_from_clue (clue);
        perm = new CellState[size];
        int extent = 0; n_blocks = blocks.length;
        range_start = new int[n_blocks];
        range_end = new int[n_blocks];
        block_start = new int[n_blocks];

        foreach (int b in blocks) {
            extent += (b + 1);
        }

        extent--;
        _freedom = size-extent;

        if (_freedom<0) {
            warning ("Invalid permutator");
        } else {
            valid = true;
        }
    }

    public void initialise () {
        int start = 0;

        for (int b = 0; b < n_blocks; b++) {
            range_start[b] = start;
            block_start[b] = range_start[b];
            range_end[b] = start + _freedom;
            start += (blocks[b] + 1);
        }

        block_start[n_blocks - 1]--; //so that next () starts with first possible permutation.
    }

    public bool next () {
        for (int b = n_blocks - 1; b >= 0; b--) {
            if (block_start[b] == range_end[b]) {
                if (range_start[b] == range_end[b]) {
                    continue;
                } else {
                    range_start[b]++;
                    block_start[b] = range_start[b];
                }
            } else {
                block_start[b]++;
                make_perm ();
                return true;
            }
        }

        return false;
    }

    private void make_perm () {
        for (int idx = 0; idx < size; idx++) {
            perm[idx] = CellState.EMPTY;
        }

        for (int b = 0; b < n_blocks; b++) {
            for (int idx = block_start[b]; idx < block_start[b] + blocks[b]; idx++) {
                perm[idx] = CellState.FILLED;
            }
        }
    }

    public CellState[] get () {
        return perm;
    }

    public string to_string () {
        var sb  = new StringBuilder ("");

        foreach (CellState cs in perm) {
            sb.append (((int)cs).to_string ());
        }

        return sb.str;
    }
}
}
