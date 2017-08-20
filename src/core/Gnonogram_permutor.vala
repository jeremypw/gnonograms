/* Gnonogram permutationutor class for Gnonograms3
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

/** Takes one region with its clue and runs through all possible patterns of given blocks
 *  in that region.
 **/
public class Permutor {
    /** PUBLIC **/
    public CellState[] permutation { get; private set; }
    public bool valid { get; private set; default = false; }

    public Permutor (int _size, string _clue) {
        size = _size;
        blocks = Utils.block_array_from_clue (_clue);
        n_blocks = blocks.length;
        range_start = new int[n_blocks];
        range_end = new int[n_blocks];
        block_start = new int[n_blocks];
        permutation = new CellState[size];

        int extent = 0;

        foreach (int b in blocks) {
            extent += (b + 1);
        }

        extent--;
        freedom = size - extent;

        if (freedom < 0) {
            warning ("Invalid permutor");
        } else {
            valid = true;
        }
    }

    public void initialise () {
        int start = 0;

        for (int b = 0; b < n_blocks; b++) {
            range_start[b] = start;
            block_start[b] = range_start[b];
            range_end[b] = start + freedom;
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
                make_permutation ();
                return true;
            }
        }

        return false;
    }

    private void make_permutation () {
        for (int idx = 0; idx < size; idx++) {
            permutation[idx] = CellState.EMPTY;
        }

        for (int b = 0; b < n_blocks; b++) {
            for (int idx = block_start[b]; idx < block_start[b] + blocks[b]; idx++) {
                permutation[idx] = CellState.FILLED;
            }
        }
    }

    public string to_string () {
        var sb  = new StringBuilder ("");

        foreach (CellState cs in permutation) {
            sb.append (((int)cs).to_string ());
        }

        return sb.str;
    }

    /** PRIVATE **/
    private int freedom;
    private int n_blocks;
    private int size;

    private int[] blocks;
    private int[] range_start; // earliest possible start point for block
    private int[] range_end; // latest possible start point for block
    private int[] block_start; //current start point for block
}
}
