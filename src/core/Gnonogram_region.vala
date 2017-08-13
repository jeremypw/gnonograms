/* Represents a linear region of cells for gnonograms -elementary
 * Copyright (C) 2010 -2017  Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY;  without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see  < http://www.gnu.org/licenses/>.
 *
 *  Author:
 *  Jeremy Wootten  < jeremy@elementaryos.org>
 */
namespace Gnonograms {

/** A region consists of a one dimensional array of cells, corresponding
 *  to a row or column of the puzzle. Associated with this are:
 *
  1) A list of block lengths (clues)
  2) A 'tag' bool array for each cell with
    *   a flag for each block indicating whether that block is still a possible owner
    *   two extra flags  - ' is completed' and ' can be empty'
  3) A 'completed blocks' bool array with
    *   a flag for each block indicating whether it is completed.
  4) A status array, one per cell indicating the status of that cell as either
    * UNKNOWN,
    * FILLED (but not necessarily assigned to a completed block),
    * EMPTY, or
    * COMPLETED (assigned to a completed block).
    *
  5) Can save and restore its state  - used to implement (one level)
     back tracking during trial and error solution ('advanced solver').

  6) Re-used if grid dimensions do not change.

**/

public class Region { /* Not a GObject, to reduce weight */
    /** PUBLIC **/
    public bool isColumn  { get; private set; }
    public bool in_error  { get; private set;  default = false; }
    public bool is_completed { get; private set; default = false; }
    public uint index  { get; private set; }
    public int nCells  { get; private set; }
    public int blockTotal { get; private set; }  //total cells to be filled
    public string message;

    public Region (My2DCellArray grid) {
        this.grid = grid;

        uint maxlen = uint.max (grid.rows, grid.cols);
        status = new CellState[maxlen];
        status_backup = new CellState[maxlen];

        uint maxblks = maxlen / 2 + 2;

        ranges = new int[maxblks, 4 + maxblks];
        ranges_backup = new int[maxblks, 4 + maxblks];

        myBlocks = new int[maxblks];

        completed_blocks = new bool[maxblks];
        completed_blocks_backup = new bool[maxblks];

        tags = new bool[maxlen, maxblks + 2];
        tags_backup = new bool[maxlen, maxblks + 2];
        //two extra flags for "can be empty" and "is finished".
    }

    public void initialize (uint index, bool isColumn, uint nCells, string clue) {
        this.index = index;
        this.isColumn = isColumn;
        this.nCells = (int)nCells;
        this.clue = clue;

        temp_status = new CellState[nCells];
        temp_status2 = new CellState[nCells];
        int[] tmpblcks = Utils.block_array_from_clue (clue);
        nBlocks = tmpblcks.length;
        can_be_empty_pointer = nBlocks;  //flag for cell that may be empty
        is_finished_pointer = nBlocks + 1;  //flag for finished cell (filled or empty?)
        blockTotal = 0;

        for (int i = 0; i < nBlocks; i++) {
          myBlocks[i] = tmpblcks[i];
          blockTotal = blockTotal + myBlocks[i];
        }

        block_extent = blockTotal + nBlocks - 1;  //minimum space needed for blocks
        initialstate ();

        if (nCells == 1) { /* Ignore single cell regions (for debugging) */
            this.is_completed = true;
        }
    }

    public void initialstate () {
        for (int i = 0; i < nBlocks; i++) {
          completed_blocks[i] = false;
          completed_blocks_backup[i] = false;
        }

        for (int i = 0; i < nCells; i++) { //Start with no possible owners and can be empty.
          for (int j = 0; j < nBlocks;  j++) {
            tags[i, j] = false;
            tags_backup[i, j] = false;
          }

          tags[i, can_be_empty_pointer] = true;
          tags[i, is_finished_pointer] = false;
          status[i] = CellState.UNKNOWN;
          temp_status[i] = CellState.UNKNOWN;
          temp_status2[i] = CellState.UNKNOWN;
        }

        in_error = false;
        is_completed = (nCells == 1);  //allows debugging of single row

        if (is_completed) {
            return;
        }

        this.unknown = 99;
        this.filled = 99;

        get_status ();

        if (myBlocks[0] == 0) { //trivial solution  - complete now
          for (int i = 0; i < nCells; i++) {
            for (int j = 0; j < nBlocks; j++) {
                tags[i, j] = false;
            }

            //Start with no possible owners and empty.
            tags[i, can_be_empty_pointer] = false;
            tags[i, is_finished_pointer] = true;
            status[i] = CellState.EMPTY;
            temp_status[i] = CellState.EMPTY;
            temp_status2[i] = CellState.EMPTY;
          }

          is_completed = true;
        } else  {
            initial_fix ();
        }

        tags_to_status ();
        put_status ();
    }

    public bool solve (bool debug, bool hint) {
        /**if change has occurred since last visit (due to change in an intersecting
         * region), runs full -fix () to see whether any inferences possible.
         * as soon as any change is made by full_fix (), updates status of
         * all cells from the tags, checks for errors or completion.
         * Repeats until no further inferences made or MAXCYCLES exceeded.
         *
         * The advanced solver relies on the error signals to implement a "trial
         * and error" method of solution when straight logic fails. An error
         * is produced when an intersecting region makes a change incompatible
         * with this region.
         *
          Ignores single cell regions for testing purposes ...
          *
          * In hint mode, return minimal change
        * */

        message = "";
        in_error = false;
        this.debug = debug;

        if (is_completed) {
            return false;
        }

        get_status ();
        //has a (valid) change been made by another region
        if (in_error) {
            return false;
        }

        if (!totals_changed ()) {
            unchanged_count++;

            if (unchanged_count > 1) {
                return false;  //allow an unchanged visit to ensure all possible changes are made.
            }
        } else {
            unchanged_count = 0;
        }

        if (is_completed) {
            return false;
        }

        int count = 0;
        bool made_changes = false;

        while (!is_completed && count < MAXCYCLES) {
            count++;
            full_fix ();

            if (in_error) {
                break;
            }

            tags_to_status ();

            if (totals_changed ()) {
                made_changes = true;

                if (in_error) {
                    break;
                }
            } else {
                break;  // no further changes made
            }
        }

        if ((made_changes && !in_error) || debug) {
            put_status ();
        }

        if (count == MAXCYCLES) {
            in_error = false;
            warning ("Excessive looping in region %s", index.to_string ());
        }

        return made_changes;
    }

    public void savestate () {
        for (int i = 0; i < nCells; i++) {
            status_backup[i] = status[i];

            for (int j = 0; j < nBlocks + 2; j++) {
                tags_backup[i, j] = tags[i, j];
            }
        }

        for (int j = 0; j < nBlocks; j++) {
            completed_blocks_backup[j] = completed_blocks[j];
        }

        is_completed_backup = this.is_completed;
        filled_backup = this.filled;
        unknown_backup = this.unknown;
    }

    public void restorestate () {
        for (int i = 0; i < nCells; i++) {
            status[i] = status_backup[i];

            for (int j = 0; j < nBlocks + 2; j++) {
                tags[i, j] = tags_backup[i, j];
            }
        }

        for (int j = 0; j < nBlocks; j++) {
            completed_blocks[j] = completed_blocks_backup[j];
        }

        is_completed = is_completed_backup;
        filled = filled_backup;
        unknown = unknown_backup;
        in_error = false;
        message = "";
        unchanged_count = 0;
    }

    public string getID () {
        string colrow;
        var sb =  new StringBuilder ("");

        if (isColumn) {
            colrow = "Column";
        } else {
            colrow = "Row";
        }

        sb.append (colrow.to_string ());
        sb.append (" ");
        sb.append (index.to_string ());
        sb.append (" Clue: ");
        sb.append (clue.to_string ());
        sb.append (" Is Completed ");
        sb.append (is_completed.to_string ());
        sb.append ("] ");

        return sb.str;
    }

    public CellState get_cell_state (uint index) {
        assert (index < nCells);
        return status[index];
    }

    /* For debugging and testing */
    public string to_string ()  {
        var sb =  new StringBuilder ("");
        sb.append (this.getID ());
        sb.append ("\n\r status before:\n\r");

        for (int i = 0; i < nCells;  i++) {
            sb.append ((temp_status[i].to_string () + "\n\r"));
        }

        sb.append ("\n\r status now:\n\r");

        for (int i = 0; i < nCells; i++) {
            sb.append ((status[i].to_string () + "\n\r"));
        }

        sb.append ("\n\rCell Status and Tags:\n\r");

        for (int i = 0; i < nCells; i++) {
            sb.append ("Cell " + i.to_string () + " Status: ");
            sb.append (status[i].to_string () + "\n\r");

            for (int j = 0; j < nBlocks;  j++) {
                sb.append (tags[i, j] ? "t" :"f");
            }

            sb.append (" : ");

            for (int j = can_be_empty_pointer; j < can_be_empty_pointer + 2; j++ ) {
                sb.append (tags[i, j] ? "t" :"f");
            }

            sb.append ("\n\r");
        }

        return sb.str;
    }

    public uint value_as_permute_region () {
        if (is_completed) {
            return 0;
        }

        int navailable_ranges = countAvailableRanges (false);

        if (navailable_ranges != 1) {
            return 0;   //useless as permute region
        }

        int block_extent = 0;
        int count = 0;
        int largest = 0;

        for (int b = 0; b < nBlocks; b++) {
            if (!completed_blocks[b]) {
                block_extent += myBlocks[b];
                count++;
                largest = int.max (largest, myBlocks[b]);
            }
        }

        int pvalue = (largest - 1) * block_extent;  //block length 1 useless

        if (count == 1) {
            pvalue = pvalue * 2;
        }

        return pvalue;
    }

    public Permutor? get_permutor (out int start) {
        string clue = "";
        start = 0;

        //Find available range (must be only one)
        if (countAvailableRanges (false) != 1) {
            return null;
        }

        int[] ablocks = get_blocks_available ();

        for (int b = 0; b < ablocks.length; b++) {
            clue = clue + myBlocks[ablocks[b]].to_string () + ", ";
        }

        start = ranges[0, 0];
        return new Permutor (ranges[0, 1], clue);
    }

    /** PRIVATE **/
    private My2DCellArray grid;

    private static int MAXCYCLES = 20;
    private static int FORWARDS = 1;
    private static int BACKWARDS =  -1;

    private bool debug;
    private bool is_completed_backup;
    private bool[] completed_blocks;
    private bool[] completed_blocks_backup;
    private bool[,] tags;
    private bool[,] tags_backup;

    private CellState[] status;
    private CellState[] temp_status;
    private CellState[] temp_status2;
    private CellState[] status_backup;

    private int unchanged_count = 0;
    private int nBlocks;
    private int block_extent;
    private int can_be_empty_pointer;
    private int is_finished_pointer;
    private int current_index;
    private int current_block_number;
    private int unknown;
    private int unknown_backup;
    private int filled;
    private int filled_backup;

    private int[] myBlocks;

    private int[,] ranges;
    private int[,] ranges_backup;

    private string clue;

    private void initial_fix () {
        //finds cells that can be identified as FILLED from the start.
        //stdout.printf ("initial_fix\n");
        int freedom = nCells - block_extent;
        int start = 0, length = 0;

        for (int i = 0; i < nBlocks; i++) {
            length = myBlocks[i] + freedom;

            for (int j = start; j < start + length; j++) {
                tags[j, i] = true;
            }

            if (freedom < myBlocks[i]) {
                set_range_owner (i, start + freedom, myBlocks[i] - freedom, true, false);
            }

            start = start + myBlocks[i] + 1;  //leave a gap between blocks
        }

        if (freedom == 0) {
            is_completed = true;
        }
    }

    private bool full_fix () {
        //stdout.printf ("Fullfix");
        // Tries each ploy in turn, returns as soon as a change is made
        // or an error detected.
        if (filled_subregion_audit () || in_error) {
            return true;
        }

        if (free_cell_audit () || in_error) {
            return true;
        }

        if (capped_range_audit () || in_error) {
            return true;
        }

        if (possibilities_audit () || in_error) {
            return true;
        }

        if (fill_gaps () || in_error) {
            return true;
        }

        if (only_possibility () || in_error) {
            return true;
        }

        if (do_edge (1) || in_error) {
            return true;
        }

        if (do_edge ( -1) || in_error) {
            return true;
        }

        if (available_filled_subregion_audit () || in_error) {
            return true;
        }

        if (fix_blocks_in_ranges () || in_error) {
            return true;
        }

        return false;
    }

    /* ******* */
    /*  PLOYS  */
    /* ******* */

    private bool filled_subregion_audit () {
    //find a range of filled cells not completed and see if can be associated
    // with a unique block.
    bool changed = false;
    bool startcapped;
    bool endcapped;
    int length;

    current_index = 0;

        while (current_index < nCells) { //find a filled sub -region
            startcapped = false;
            endcapped = false;
            current_index = skipWhileNotStatus (CellState.FILLED, current_index, nCells, 1);

            if (current_index == nCells) {
                break;
            }

            //found first FILLED cell;  current_index points to it
            if (tags[current_index, is_finished_pointer]) {
                current_index++;
                continue;
            }//ignore if completed already

            if (current_index == 0 || status[current_index - 1] == CellState.EMPTY) {
                startcapped = true;  //edge cell
            }

            length = countNextState (CellState.FILLED, current_index, true); //current_index not changed
            int lastcell = current_index + length - 1; //last filled cell in this (partial) block

            if (lastcell == nCells - 1 || status[lastcell + 1] == CellState.EMPTY) {
                endcapped = true;  //last cell is at edge
            }

            //is this region fully capped?
            if (startcapped && endcapped) {  // assigned block must fit exactly
                assignAndCapRange (current_index, length);
                current_index += length + 1;
                continue;
            } else { //find largest possible owner of this (partial) block
                int largest = find_largest_possible_block_for_cell (current_index);

                if (largest == length) {//there is **at least one** largest block that fits exactly.
                    // this region must therefore be complete
                    assignAndCapRange (current_index, length);
                    current_index += length + 1;
                    changed = true;
                    continue;
                }

                // remove blocks that are smaller than length from this region
                int start = current_index;
                int end = current_index + length - 1;  // last filled cell

                for (int bl = 0; bl < nBlocks; bl++) {
                    for (int i = start; i <= end; i++) {

                        if (tags[i, bl] && myBlocks[bl] < length) {
                            tags[i, bl] = false;
                        }
                    }
                }

                // For the adjacent cells (if not at edge) the minimum length
                // of the owner is one higher.
                if (start > 0) {
                    start--;

                    for (int bl = 0; bl < nBlocks; bl++) {
                        if (tags[start, bl] && myBlocks[bl] < length + 1) {
                            tags[start, bl] = false;
                        }
                    }
                }

                if (end < nCells - 1) {
                    end++;

                    for (int bl = 0; bl < nBlocks; bl++) {
                        if (tags[end, bl] && myBlocks[bl] < length + 1) {
                            tags[end, bl] = false;
                        }
                    }
                }

                if (startcapped || endcapped) {//semi-capped  - can we extend it?
                  int smallest = find_smallest_possible_block_for_cell (current_index);

                    if (smallest > length) {//can extend by smallest -length away from cap
                        int ptr;

                        if (startcapped) {
                          ptr = current_index + length;

                            for (int i = 0; i < smallest - length; i++) {

                                if (ptr < nCells) {
                                    tags[ptr, can_be_empty_pointer] = false;
                                    ptr++;
                                }
                            }
                        } else {
                            ptr = current_index - 1;

                            for (int i = 0; i < smallest - length; i++) {
                                if (ptr >= 0) {
                                    tags[ptr, can_be_empty_pointer] = false;
                                    ptr --;
                                }
                            }
                        }

                        tags_to_status ();
                        changed = true;
                    }
                }
            }

            current_index += length; //move past block  - if reaches here no operations have been performed on block
        }

        return changed;
    }

    private bool fill_gaps () {
        // Find unknown gap between filled cells and complete accordingly.
        bool changed = false;

        for (int idx = 0; idx < nCells - 2; idx++) {

            if (status[idx] != CellState.FILLED) {
                continue;  //find a FILLED cell
            }

            if (status[idx + 1] != CellState.UNKNOWN) {
                    continue;  //is following cell empty?
            }

            if (!has_one_owner (idx)) {  // if owner ambiguous, can only deal with single cell gap
                // see if single cell gap which can be marked empty because
                // to fill it would create a block larger than any permissible.
                if (status[idx + 2] != CellState.FILLED) {
                    continue;  //cell after that filled?
                }
                // we have found a one cell gap
                // calculate total length if gap were to be FILLED.
                int blength = countNextState (CellState.FILLED, idx + 2, true) +
                              countNextState (CellState.FILLED, idx, false) + 1;

                bool mustbeempty = true;

                //look for a possible owner at least as long as combined length
                for (int bl = 0; bl < nBlocks; bl++) {

                    if (tags[idx, bl] && myBlocks[bl] >= blength) { //possible owner found  - gap could be filled
                        mustbeempty = false;
                        break;
                    }
                }

                //no permissible blocks large enough
                if (mustbeempty) {
                    set_cell_empty (idx + 1);
                    changed =  true;
                } else {
                    // see if setting empty would create two regions one or more of which
                    // is too small for the available blocks
                    bool mustNotBeEmpty = false;
                    int lengthLeft = 0, lengthRight = 0;
                    int ptr = idx;

                    //left -hand region
                    while (ptr >= 0 && !tags[ptr, is_finished_pointer]) {
                        ptr--;
                        lengthLeft++;
                    }

                    ptr = idx + 2;

                    //right -hand region
                    while (ptr < nCells && !tags[ptr, is_finished_pointer]) {
                        ptr++;
                        lengthRight++;
                    }

                    //find largest, earliest possible block fitting in first range
                    int countLeft = 0, countRight = 0, totalCount;
                    ptr = idx;  //cell before gap

                    for (int i = 0; i < nBlocks; i++) {
                        if (tags[ptr, i] && myBlocks[i] <= lengthLeft) {
                            countLeft++;
                        }
                    }

                    ptr = idx + 2;  //cell after gap

                    for (int i = 0; i < nBlocks; i++) {
                        if (tags[ptr, i] && myBlocks[i] <= lengthRight) {
                            countRight++;
                        }
                    }

                    totalCount = countLeft + countRight;

                    if (totalCount == 2) {

                        for (int i = 0; i < nBlocks; i++) {

                            if (tags[ptr, i] && myBlocks[i] <= lengthRight) {

                                if (tags[idx, i] && myBlocks[i] <= lengthLeft) {
                                    mustNotBeEmpty = true;  // only one block fits in both sides
                                }
                            }
                        }
                    } else if (totalCount < 2) {
                        mustNotBeEmpty = true;
                    }

                    if (mustNotBeEmpty) {
                        tags[idx + 1, can_be_empty_pointer] = false;
                        changed = true;
                    }
                }

                idx += 2;  //skip gap
            } else { //only one possible owner of first FILLED cell
                int cell1 = idx;  //start of gap
                idx++;

                //skip to end of gap
                while (idx < nCells - 1 && status[idx] == CellState.UNKNOWN) {
                    idx++;
                }

                if (status[idx] != CellState.FILLED) {
                    continue;  //gap ends with empty cell  - abandon this gap
                } else { //if start and end of gap have same owner, fill in the gap.
                    int owner = have_same_owner (cell1, idx);
                    if (owner >= 0) {
                        changed = set_range_owner (owner, cell1, idx - cell1 + 1, true, false) || changed;
                    }

                    idx--;
                }
            }
        }

        return changed;
    }

    private bool possibilities_audit () {
    //find a unique possible range for block if there is one.
        //eliminates ranges that are too small
        int start, length, count;
        bool changed = false;

        for (int i = 0; i < nBlocks; i++) {

            if (completed_blocks[i]) {
                continue;  //skip completed block
            }

            start = 0;
            length = 0;
            count = 0;  //how many possible ranges for this block

            for (int idx = 0; idx < nCells; idx++) {

                if (count > 1) {
                    break;  //no unique range  - try next block
                }

                if (!tags[idx, i] || tags[idx, is_finished_pointer]) {
                    continue;  //cell not possible for this block or already completed
                }

                int s = idx;  //first cell with block i as possible owner
                int l = countnextowner (i, idx);  //length of contiguous cells having this block (i) as a possible owner.

                if (l < myBlocks[i]) {
                    remove_block_from_range (i, s, l, 1); //block cannot be here
                } else {
                    length = l;
                    start = s;
                    count++;
                }

                idx += l - 1;  //allow for incrementing on next loop
            }

            if (count != 1) {
                continue;  //no unique range found
            } else { //perhaps some cells can be assigned but
                //this range not proved exclusive to this block;
                changed = fix_block_in_range (i, start, length) || changed;
            }
        }

        return changed;
    }

    private void assignAndCapRange (int start, int length) {
        //make list of possible blocks with right length in maxblks[]
        //record which is first and which last (in order).
        //always changes at least one cell status

        int count = 0;
        int[] maxblks = new int[nBlocks];
        int first = nBlocks;
        int last = 0;
        int end = start + length - 1;

        for (int i = 0; i < nBlocks; i++) {

            if (completed_blocks[i]) {
                continue;
            }

            if (myBlocks[i] != length) {
                continue;
            }

            if (!tags[start, i] || !tags[end, i]) {
                continue;
            }

            maxblks[count] = i;
            count++;

            if (i < first) {
                first = i;
            }

            if (i > last) {
                last = i;
            }
        }

        if (count == 0) {
            return;  //no matching block  - range is not complete
        }

        if (count == 1) {  //unique owner
            set_block_complete_and_cap (maxblks[0], start, 1);
        } else { //ambiguous owner
            //delete out of sequence blocks before end of range
            for (int i = last + 1; i < nBlocks; i++) {
                remove_block_from_cell_to_end (i, start + length - 1,  -1);
            }

            //delete out of sequence blocks after start of range
            for (int i = 0; i < first; i++) {
                remove_block_from_cell_to_end (i, start, 1);
            }

            //remove as possible owner blocks between first and last that are wrong length
            for (int i = first + 1; i < last; i++) {

                if (myBlocks[i] == length) {
                    continue;
                }

                remove_block_from_range (i, start, length, 1);
            }

            //for each possible mark as possible owner of subregion (not exclusive)
            for (int i = 0; i < count; i++) {
                set_range_owner (maxblks[i], start, length, false, false);
            }

            // cap range
            if (start > 0) {
                set_cell_empty (start - 1);
            }

            if (start + length < nCells) {
                set_cell_empty (start + length);
            }
        }
    }

    private bool only_possibility () {
        //find an unfinished cell with only one possibility
        //remove this block from cells out of range
        int owner;
        int length;
        int start;

        for (int i = 0; i < nCells; i++) {
            if (tags[i, is_finished_pointer]) {
                continue;
            }

            // unfinished cell found
            if (status[i] == CellState.FILLED && has_one_owner (i)) { //cell is FILLED and has only one owner
                //find the owner
                for (owner = 0; owner < nBlocks; owner++) {
                    if (tags[i, owner]) {
                        break;
                    }
                }

                length = myBlocks[owner];
                //remove this block from earlier cells our of range
                start = i - length;
                if (start >= 0) {
                    remove_block_from_cell_to_end (owner, start, BACKWARDS);
                }

                //remove this block from later cells our of range
                start = i + length;
                if (start < nCells) {
                    remove_block_from_cell_to_end (owner, start, FORWARDS);
                }
            }
        }

        return false;  //always false  - only changes tags
    }

    private bool free_cell_audit () {
        // Compare  number of UNKNOWN cells with the number of unassigned
        // block cells.
        // If they are the same then mark all UNKNOWN cells as
        // FILLED and mark all blocks COMPLETE.
        // If there are no unassigned block cells then mark all UNKNOWN
        // cells as EMPTY.

        int freecells = count_cell_state (CellState.UNKNOWN);

        if (freecells == 0) {
            return false;
        }

        int filledcells = count_cell_state (CellState.FILLED);
        int completedcells = count_cell_state (CellState.COMPLETED);
        int tolocate = blockTotal - filledcells - completedcells;

        if (freecells == tolocate) { // Set all UNKNOWN as COMPLETE
            for (int i = 0; i < nCells; i++) {
                if (status[i] == CellState.UNKNOWN) {
                    set_cell_complete (i);
                }
            }

            for (int i = 0; i < nBlocks; i++) {
                completed_blocks[i] = true;
            }

            return true;
        } else if (tolocate == 0) {
            for (int i = 0; i < nCells; i++) {

                if (status[i] == CellState.UNKNOWN) {
                    set_cell_empty (i);
                }

                is_completed = true;
            }

            return true;
        }

        return false;
    }

    private bool do_edge (int direction) {
        // Scan forward (or backward) from an edge searching for filled cells
        // that are nearer than length of first (or last) block.
        // FILL cells after that to length of first (or last) block.
        // Look for FILLED cell just out of range - edge can be moved forward
        // direction: 1 = FORWARDS, -1 = BACKWARDS

        int limit; //first out of range value of idx depending on direction
        bool dir = (direction == FORWARDS);

        if (dir) {
            current_index = 0;
            current_block_number = 0;
            limit = nCells;
        } else {
            current_index = nCells - 1;
            current_block_number = nBlocks - 1;
            limit = -1;
        }

        //Find first edge - skipping completed cells
        if (!findEdge (limit, direction)) {
            return false;
        }

        //current_index points to cell on the edge
        if (status[current_index] == CellState.FILLED) {
            //first cell is FILLED. Can complete whole block
            return set_block_complete_and_cap (current_block_number, current_index, direction);
        } else {  // see if filled cell in range of first block and complete after that
            int edgestart = current_index;
            int fillstart = -1;
            int blength = myBlocks[current_block_number];
            int blocklimit = (dir? current_index + blength : current_index - blength);

            if (blocklimit < -1 || blocklimit > nCells) {
                in_error = true;
                message = "Invalid blocklimit";
                return false;
            }

            current_index = skipWhileNotStatus (CellState.FILLED, current_index, blocklimit, direction);

            if (current_index != blocklimit) {
                fillstart = current_index;
                bool changed = false;

                while (current_index != blocklimit) {
                    if (status[current_index] == CellState.UNKNOWN) {
                        set_cell_owner (current_index, current_block_number, true, false);
                    }

                    if (dir) {
                        current_index++;
                    } else {
                        current_index--;
                    }
                }

                // current_index now points to cell after earliest possible end of block
                // if this is a filled cell then first cell in range must be empty
                // continue setting cells at beginning of range empty until
                // an unfilled cell found. FILL cells beyond first FILLED cells.
                // remove block from out of range of first filled cell.

                while (current_index != blocklimit && status[current_index] == CellState.FILLED) {
                    set_cell_owner (current_index, current_block_number, true, false);
                    set_cell_empty (edgestart);
                    changed = true;

                    if (dir) {
                        current_index++;
                        edgestart++;
                    } else {
                        current_index--;
                        edgestart--;
                    }
                }

                //if a fillable cell was found then fillstart > 0
                if (fillstart > 0) {
                    //delete block more than block length from where filling started
                    current_index = fillstart + (dir ? blength : -blength);

                    if (current_index >= 0 && current_index < nCells) {
                        remove_block_from_cell_to_end (current_block_number, current_index, direction);
                    }
                }

                return changed;
            }
        }

        return false;
    }

    private bool findEdge (int limit, int direction) {
        // Edge is first FILLED or UNKNOWN cell from limit of region.
        //starting point is set in current_index and current_block_number before calling.
        //stdout.printf (this.toString ());
        bool dir = (direction == FORWARDS);
        int loopstep = dir ? 1 : -1;

        for (int i = current_index; (i >= 0 && i < nCells); i += loopstep) {
            if (status[i] == CellState.EMPTY) {
                continue;
            }

            //now pointing at first cell of filled or unknown block after edge
            if (tags[i, is_finished_pointer]) {  //skip to end of finished block
                i += (dir ? myBlocks[current_block_number] - 1 : 1 - myBlocks[current_block_number]);
                //now pointing at last cell of filled block
                current_block_number += loopstep;  //Increment or decrement current block as appropriate

                if (current_block_number < 0 || current_block_number == nBlocks) {
                    record_error ("FindEdge", "Invalid BlockNum");
                    return false;
                }
            } else {
                current_index = i;
                return true;
            }
        }

        return false;
    }

    private bool fix_blocks_in_ranges () {
        // blocks may have been marked completed  - thereby reducing available ranges
        int[] availableBlocks = get_blocks_available ();
        int bl = availableBlocks.length;
        int[,] blockstart = new int[bl, 2];  //range number and offset of earliest start point
        int[,] blockend = new int[bl, 2];  //range number and offset of latest end point

        //update ranges with currently available ranges (can contain only unknown  and incomplete cells)
        int numberOfAvailableRanges = countAvailableRanges (false);

        //find earliest start point of each block (treating ranges as all unknown cells)
        int rng = 0;
        int offset = 0;
        int length = 0;
        int ptr;

        for (int b = 0; b < bl; b++) {//for each available block
            length = myBlocks[availableBlocks[b]];  //get its length

            if (ranges[rng, 1] < (length + offset)) {//cannot fit in current range
                rng++;
                offset = 0; //skip to start of next range

                while (rng < numberOfAvailableRanges && ranges[rng, 1] < length) {
                    rng++; //keep skipping if too small
                }

                if (rng >= numberOfAvailableRanges) {
                    return false;
                }
            }

            //look for collision with filled cell
            ptr = ranges[rng, 0] + offset + length;  //cell after end of block

            while (ptr < nCells && !tags[ptr, can_be_empty_pointer]) {
                ptr++;
                offset++;
            }

            blockstart[b, 0] = rng;  //set start range number
            blockstart[b, 1] =  offset;  //and start point
            offset += (length + 1);  //move offset allowing for one cell gap between blocks
        }

        //carry out same process in reverse to get latest end points
        rng = numberOfAvailableRanges - 1;
        offset = 0;  //start at end of last range NB offset now counts from end

        for (int b = bl - 1; b >= 0; b --) { //start at last block
            length = myBlocks[availableBlocks[b]];  //get length
            if (ranges[rng, 1] < (length + offset)) { //doesn't fit
                rng --;
                offset = 0;

                while (rng >= 0 && ranges[rng, 1] < length) {
                    rng --;  //keep skipping if too small
                }

                if (rng < 0) {
                    return false;
                }
            }

            //look for collision with filled cell
            ptr = ranges[rng, 0] + ranges[rng, 1] - (offset + length) - 1;  //cell before beginning of block

            while (ptr >= 0 && !tags[ptr, can_be_empty_pointer]) {
                ptr --;
                offset++;
            }

            blockend[b, 0] = rng;  //set end range number
            blockend[b, 1] =  ranges[rng, 1] - offset;   //and end point
            //NB end point is index of cell AFTER last possible cell so that
            //subtracting start from end gives length of range.
            offset += (length + 1);  //shift offset allowing for one cell gap
        }

        int start;

        for (int b = 0; b < bl; b++) { //for each available block
            rng = blockstart[b, 0];
            offset = blockstart[b, 1];
            start = ranges[rng, 0];

            if (rng == blockend[b, 0]) { //if starts and ends in same range
                length = blockend[b, 1] - blockstart[b, 1];
                //'length' now used for total length of possible range for this block
                fix_block_in_range (availableBlocks[b], start + offset, length);
            }

            //remove block from outside possible range
            if (offset > 1) {
                remove_block_from_range (availableBlocks[b], start, offset - 1, 1);
            }

            for (int r = 0; r < blockstart[b, 0]; r++) { //ranges before possible
                remove_block_from_range (availableBlocks[b], ranges[r, 0], ranges[r, 1], 1);
            }

            rng = blockend[b, 0];
            start = ranges[rng, 0] + blockend[b, 1];
            length = ranges[rng, 1] - blockend[b, 1];

            if (length > 0) {
                remove_block_from_range (availableBlocks[b], start, length, 1);
            }

            for (int r = numberOfAvailableRanges - 1; r > blockend[b, 0]; r--) { //ranges after possible
                remove_block_from_range (availableBlocks[b], ranges[r, 0], ranges[r, 1], 1);
            }
        }

        return false;
    }

    private bool capped_range_audit () {
        // For each capped range (contiguous filled cells bounded on both
        // ends by an edge or an empty cell), remove as owner all blocks
        // of the wrong size. Check there is at least one possible owner
        // else return an error.
        // only changes tags so returns false
        int start = 0;
        int length = 0;
        int idx = 0;
        int nranges = countcappedranges ();

        if (nranges == 0) {
            return false;
        }

        for (int rng = 0; rng < nranges; rng++) {
            start = ranges[rng, 0];
            length = ranges[rng, 1];

            for (idx = start; idx < start + length; idx++) {
                int count = 0;

                for (int b = 0; b < nBlocks; b++) {

                    if (tags[idx, b]) {
                        count++;

                        if (myBlocks[b] != length) {
                            tags[idx, b] = false;
                            count--;
                        }
                    }
                }

                if (count == 0) {
                    record_error ("capped range audit", "filled cell with no owners", false);
                    return false;
                }
            }
        }

        return false;
    }

    private bool available_filled_subregion_audit () {
        //test whether there is an unambiguous distribution of available blocks amongs available filled subregions.

        int idx = 0;
        int start = 0;
        int end = nCells;
        int countRegions = 0;
        Range[] availableSubRegions = new Range[nCells / 2];  //start and end of each subregion

        while (idx < nCells) {
            if (status[idx] != CellState.FILLED) {
                idx++;
                continue;
            }

            countRegions++;

            if (countRegions <= nBlocks) {
                start = idx;
            } else {
                return false;
            }

            while (idx < nCells && status[idx] == CellState.FILLED) {
                idx++;
            }

            end = idx - 1;  //last filled cell
            availableSubRegions[countRegions - 1] = new Range (start, end,  -1,  -1);
        }

        if (countRegions < 2 || countRegions > nBlocks) {
            return false;
        }

        //now see how many blocks could fit here;
        int[] availableBlocks = get_blocks_available ();
        int nAvailableBlocks = availableBlocks.length;

        if (countRegions > nAvailableBlocks) {
            return false;
        }

        int firstStart = availableSubRegions[0].start;
        int length = availableSubRegions[0].length ();
        int lastEnd = availableSubRegions[countRegions - 1].end;

        //delete available blocks up to first in the first subregion
        int countBlocks = nAvailableBlocks;
        int bl;

        for (int i = 0; i < nAvailableBlocks; i++) {
            bl = availableBlocks[i];

            if (!tags[firstStart, bl]) {
                availableBlocks[i] = -1;
                countBlocks --;
            } else {
                break;
            }
        }

        for (int i = nAvailableBlocks - 1; i >= 0; i --) {
            bl = availableBlocks[i];

            if (bl >= 0 && !tags[lastEnd, bl]) {
                availableBlocks[i] = -1;
                countBlocks --;
            } else {
                break;
            }
        }

        if (countBlocks != countRegions) {
            return false;
        }

        int[] candidates =  new int[countBlocks];
        int countCandidates = 0;
        int combinedLength = 0;

        for (int i = 0; i < nAvailableBlocks; i++) {
            if (availableBlocks[i] < 0) {
                continue;
            } else {
                candidates[countCandidates] = availableBlocks[i];
                combinedLength += myBlocks[availableBlocks[i]];
                countCandidates++;
            }
        }

        combinedLength += (countCandidates - 1);  //allow for gap of at least 1 between blocks

        // for unambiguous assignment all sub regions must be separated by more than
        // the combined length of the candidate blocks and gaps
        int overallLength = lastEnd - firstStart + 1;

        if (overallLength < combinedLength) {
            return false;
        }

        //consecutive regions must be separated so one block cannot cover both
        //either by finished cell or by distance

        for (int ar = 0; ar < countRegions - 1; ar++) {
            bool separate = false;

            for (int i = availableSubRegions[ar].end; i < availableSubRegions[ar + 1].start; i++) {

                if (tags[i, is_finished_pointer]) {
                    separate = true;
                    break;
                }
            }

            if (separate) {
                continue;  //separated by empty or complete cell
            } else {
                start = availableSubRegions[ar].start;
                end = availableSubRegions[ar + 1].end;
                length = end - start + 1;

                if (length <= myBlocks[candidates[ar]] || length <= myBlocks[candidates[ar + 1]]) {
                    return false;  //too close
                }
            }
        }

        //Unambiguous assignment possible
        if (countRegions > countCandidates) {
            in_error = true;
            return false;
        }

        for (int ar = 0; ar < countRegions; ar++) {
            bl = candidates[ar];
            length = myBlocks[bl];
            set_range_owner (bl, availableSubRegions[ar].start, availableSubRegions[ar].length (), true, false);
        }

        return false;   //only changes tags
    }

    // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==
    // END OF PLOYS
    // HELPER FUNCTIONS FOLLOW
    // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==

    private int skipWhileNotStatus (int cs, int idx, int limit, int direction) {
        // increments/decrements idx until cell of required state
        // or end of range found.
        // returns idx of cell with status cs if found else limit

        if (limit < -1 || limit > nCells) {
            in_error = true;
            return 0;
        }

        if ((direction == Region.FORWARDS) && idx >= limit)  {
            return limit;
        } else if ((direction == Region.BACKWARDS) && (idx <= limit)) {
            return limit;
        }

        for (int i = idx; i != limit; i += direction) {

            if (status[i] == cs)  {
                return i;
            }
        }

        return limit;  //false;
    }

    private int countNextState (int cs, int idx, bool forwards) {
        // count how may consecutive cells of state cs starting at given
        // index idx (inclusive of starting cell)

        int count = 0;

        if (forwards && idx >= 0) {

            while (idx < nCells && status[idx] == cs) {
                count++;
                idx++;
            }
        } else if (!forwards && idx < nCells) {

            while (idx >= 0 && status[idx] == cs) {
                count++;
                idx--;
            }
        } else {
            in_error = true;
        }

        return count;
    }

    private int countnextowner (int owner, int idx) {
        // count how may consecutive cells with owner possible starting
        // at given index idx?

        int count = 0;

        if (idx >= 0) {
            while (idx < nCells && tags[idx, owner] && !tags[idx, is_finished_pointer]) {
                count++;
                idx++;
            }
        } else {
            in_error = true;
        }

        return count;
    }

    private int countAvailableRanges (bool notempty) {
        // determine location of ranges of unknown or unfinished filled cells
        // and store in ranges[, ]
        // ranges[ , 0] indicates start point,
        // ranges[ , 1] indicates length
        // ranges[ , 2] indicates number of filled,
        // ranges[ , 3] indicates number of unknown

        int range = 0;
        int start = 0;
        int length = 0;
        int idx = 0;

        //skip to start of first range;
        while (idx < nCells && tags[idx, is_finished_pointer]) {
            idx++;
        }

        while (idx < nCells) {
            length = 0;
            start = idx;
            ranges[range, 0] = start;
            ranges[range, 2] = 0;
            ranges[range, 3] = 0;

            while (idx < nCells && !tags[idx, is_finished_pointer]) {

                if (!tags[idx, can_be_empty_pointer]) {
                    ranges[range, 2]++;  //FILLED
                } else {
                    ranges[range, 3]++;  //UNKNOWN
                }

                idx++;
                length++;
            }

            if (!notempty || ranges[range, 2] != 0) {
                ranges[range, 1] = length;
                range++;
            }

            //skip to beginning of next range
            idx++;

            while (idx < nCells && tags[idx, is_finished_pointer]) {
                idx++;
            }
        }

        return range;  //number of ranges  - not last index!
    }

    private bool checkNumberOfBlocks () {
        //only called when region is completed. Checks whether number of blocks is correct

        int count = 0, idx = 0;

        while (idx < nCells) {

            while (idx < nCells && status[idx] == CellState.EMPTY) {
                idx++;
            }

            if (idx < nCells) {
                count++;
            } else {
                break;
            }

            while (idx < nCells && status[idx] != CellState.EMPTY) {
                idx++;
            }
        }

        if (count != nBlocks) {
          record_error ("Check nBlocks", "Wrong number of blocks found " + count.to_string () + " should be " + nBlocks.to_string ());
          return false;
        } else {
            return true;
        }
    }

    private int countcappedranges () {
        // determine location of capped ranges of filled cells (not marked complete) and store in ranges[, ]

        int range = 0;
        int start = 0;
        int length = 0;
        int idx = 0;

        while (idx < nCells && status[idx] != CellState.FILLED) {
            idx++;  //skip to beginning of first range
        }

        while (idx < nCells) {
            length = 0;
            start = idx;
            ranges[range, 0] = start;
            ranges[range, 2] = 0;  //not used
            ranges[range, 3] = 0;  //not used

            while (idx < nCells && status[idx] == CellState.FILLED) {
                idx++;
                length++;
            }

            if ((start == 0 || status[start - 1] == CellState.EMPTY) &&
                (idx == nCells || status[idx] == CellState.EMPTY)) { //capped

                ranges[range, 1] = length;
                range++;
            }

            idx++;

            while (idx < nCells && status[idx] != CellState.FILLED) {
                idx++;  //skip to beginning of next range
            }
        }

        return range;
    }

    private int count_possible_owners_and_can_be_empty (int cell) {
        // how many possible owners?  Does include can be empty tag!

        int count = 0;

        if (is_invalid_data (cell)) {
            in_error = true;
        } else {
            for (int j = 0; j < nBlocks; j++) {
                if (tags[cell, j]) {
                    count++;
                }
            }

            if (tags[cell, can_be_empty_pointer]) {
                count++;
            }
        }

        if (count == 0) {
            in_error = true;
        }

        return count;
    }

    private int count_cell_state (int cs) {
        //how many times does state cs occur in range.

        int count = 0;

        for (int i = 0; i < nCells; i++) {
            if (status[i] == cs) {
                count++;
            }
        }

        return count;
    }

    private int[] get_blocks_available () {
        //array of incomplete block indexes

        int[] blocks = {};

        for (int i = 0; i < nBlocks; i++) {
            if (!completed_blocks[i]) {
                blocks += i;
            }
        }

        return blocks;
    }

    private int have_same_owner (int cell1, int cell2) {
        //checks if both the same single possible owner.
        //return owner if same owner else  -1

        int count = 0;
        int owner = -1;
        bool tmp;

        if (cell1 < 0 || cell1 >= nCells || cell2 < 0 || cell2 >= nCells) {
            in_error = true;
        } else {

            for (int i = 0; i < nBlocks; i++) {
                tmp = tags[cell1, i];

                if (count > 1 ||  (tmp != tags[cell2, i])) {
                    owner = -1;
                    break;
                } else if (tmp) {
                    count++;
                    owner = i;
                }
            }
        }

        return owner;
    }

    private bool has_one_owner (int cell) {
        // if only one possible owner (if not empty) then return true

        int count = 0;

        for (int i = 0; i < nBlocks; i++) {

            if (tags[cell, i]) {
                count++;
            }

            if (count > 1) {
                break;
            }
        }

        return count == 1;
    }

    private bool fix_block_in_range (int block, int start, int length) {
        // block must be limited to range

        bool changed = false;

        if (is_invalid_data (start, block, length)) {
          in_error = true;
        } else {
            int blocklength = myBlocks[block];
            int freedom = length - blocklength;

            if (freedom < 0) {
                record_error ("Fix block in range", "block longer than range", false);
                return false;
            }

            if (freedom < blocklength) {

                if (freedom == 0) {
                    set_block_complete_and_cap (block, start, 1);
                    changed = true;
                } else {
                    set_range_owner (block, start + freedom, blocklength - freedom, true, false);
                }
            }
        }

        return changed;
    }

    private int find_largest_possible_block_for_cell (int cell) {
        // find the largest incomplete block possible for given cell

        int maxsize = -1;

        for (int i = 0; i < nBlocks; i++) {

            if (!tags[cell, i]) {
                continue;  // not possible
            }

            if (myBlocks[i] <= maxsize) {
                continue;  // not largest
            }

            maxsize = myBlocks[i];  //update largest
        }

        return maxsize;
    }

    private int find_smallest_possible_block_for_cell (int cell) {
        // find the smallest incomplete block possible for given cell

        int minsize = 9999;

        for (int i = 0; i < nBlocks; i++) {
            if (!tags[cell, i]) {
                continue;  // not possible
            }

            if (myBlocks[i] >= minsize) {
                continue;  // not largest
            }

            minsize = myBlocks[i];  //update largest
        }

        if (minsize == 9999) {
            record_error ("findsmallest possible in cell", "No block possible in " + cell.to_string ());
            return 0;
        }

        return minsize;
    }

    private void remove_block_from_cell_to_end (int block, int start, int direction) {
        //remove block as possibility after/before start
        //bi-directional forward = 1 backward  =  -1
        //if reverse direction then equivalent forward range is used
        //only changes tags

        int length = direction > 0 ? nCells - start : start + 1;
        start = direction > 0 ? start : 0;

        if (length > 0) {
            remove_block_from_range (block, start, length, 1);
        }
    }

    private void remove_block_from_range (int block, int start, int length, int direction) {
        //remove block as possibility in given range
        //bi-directional forward = 1 backward  =  -1
        //if reverse direction then equivalent forward range is used
        //only changes tags

        if (direction < 0) {
            start = start - length + 1;
        }

        if (is_invalid_data (start, block, length)) {
            in_error = true;
        } else  {

            for (int i = start; i < start + length; i++) {
                tags[i, block] = false;
            }
        }
    }

    private bool set_block_complete_and_cap (int block, int start, int direction) {
        //returns true  - always changes a cell status if not in error

        bool changed = false;
        int length = myBlocks[block];

        if (direction < 0) {
            start = start - length + 1;
        }

        if (is_invalid_data (start, block, length)) {
            in_error = true;
            return false;
        }

        if (completed_blocks[block] == true && tags[start, block] == false) {
            in_error = true;
            return false;
        }

        completed_blocks[block] = true;
        set_range_owner (block, start, length, true, false);

        if (start > 0 && !tags[start - 1, is_finished_pointer]) {
            changed = true;
            set_cell_empty (start - 1);
        }

        if (start + length < nCells && !tags[start + length, is_finished_pointer]) {
            changed = true;
            set_cell_empty (start + length);
        }

        for (int cell = start; cell < start + length; cell++) {
            set_cell_complete (cell);
        }

        //taking into account minimum distance between blocks.
        // constrain the preceding blocks if this are at least two
        int l;

        if (block > 1) { //at least third block
            l = 0;

            for (int bl = block - 2; bl >= 0; bl--) {
                l = l + myBlocks[bl + 1] + 1; // length of exclusion zone for this block
                remove_block_from_range (bl, start - 2, l, -1);
            }
        }

        // constrain the following blocks if there are at least two
        if (block < nBlocks - 2) {
            l = 0;

            for (int bl = block + 2; bl <= nBlocks - 1; bl++) {
                l = l + myBlocks[bl - 1] + 1; // length of exclusion zone for this block
                remove_block_from_range (bl, start + length + 1, l, 1);
            }
        }

        return changed;   //if block was not already capped
    }


    private bool set_range_owner (int owner, int start, int length, bool exclusive, bool canbeempty) {
        bool changed = false;

        if (is_invalid_data (start, owner, length)) {
            in_error = true;
            return false;
        } else {
            int blocklength = myBlocks[owner];

            for (int cell = start; cell < start + length; cell++) {
                set_cell_owner (cell, owner, exclusive, canbeempty);
            }

            if (exclusive) {
                //remove block and out of sequence from regions out of reach if exclusive
                if (blocklength < length && !canbeempty) {
                    in_error = true;
                    return false;
                }

                int bstart = int.min (start - 1, start + length - blocklength);

                if (bstart >= 0) {
                    remove_block_from_cell_to_end (owner, bstart - 1,  -1);
                }

                int bend = int.max (start + length, start + blocklength);

                if (bend < nCells) {
                    remove_block_from_cell_to_end (owner, bend, 1);
                }

                int earliestend = start + length;

                for (int bl = nBlocks - 1; bl > owner; bl --) { //following blocks cannot be earlier
                    remove_block_from_cell_to_end (bl, earliestend, -1);
                }

                int lateststart = start - 1;

                for (int bl = 0; bl < owner; bl++) { //preceding blocks cannot be later
                    remove_block_from_cell_to_end (bl, lateststart, 1);
                }
            }
        }

        return changed;
    }

    private bool set_cell_owner (int cell, int owner, bool exclusive, bool canbeempty) {
        //exclusive  - cant be any other block here
        //can be empty  - self evident

        bool changed = false;

        if (is_invalid_data (cell, owner)) {
            in_error = true;
        } else if (status[cell] == CellState.EMPTY) {// do nothing  - not necessarily an error
        } else if (status[cell] == CellState.COMPLETED && tags[cell, owner] == false) {
            record_error ("set_cell_owner", "contradiction cell " + cell.to_string () + " filled but cannot be owner");
        } else {
            if (exclusive) {
                for (int i = 0; i < nBlocks; i++) {
                    tags[cell, i] = false;
                }
            }

            if (!canbeempty) {
                status[cell] = CellState.FILLED;
                changed = true;
                tags[cell, can_be_empty_pointer] = false;
            }

            tags[cell, owner] = true;
        }

        return changed;
    }

    private void set_cell_empty (int cell) {
        if (is_invalid_data (cell)) {
            record_error ("set_cell_empty", "cell " + cell.to_string () + " invalid data");
        } else if (tags[cell, can_be_empty_pointer] == false) {
            record_error ("set_cell_empty", "cell " + cell.to_string () + " cannot be empty");
        } else if (is_cell_filled (cell)) {
            record_error ("set_cell_empty", "cell " + cell.to_string () + " is filled");
        } else {

            for (int i = 0; i < nBlocks; i++) {
                tags[cell, i] = false;
            }

            tags[cell, can_be_empty_pointer] = true;
            tags[cell, is_finished_pointer] = true;
            status[cell] = CellState.EMPTY;
        }
    }

    private void set_cell_complete (int cell) {
        if (status[cell] == CellState.EMPTY) {
            record_error ("set_cell_complete", "cell " + cell.to_string () + " already set empty");
        }

        tags[cell, is_finished_pointer] = true;
        tags[cell, can_be_empty_pointer] = false;
        status[cell] = CellState.COMPLETED;
    }

    private bool is_invalid_data (int start, int block = 0, int length = 1) {
        return (start < 0 ||
                start >= nCells ||
                length < 0 ||
                start + length > nCells ||
                block < 0 ||
                block >= nBlocks);
    }

    private bool is_cell_filled (int cell) {
        return (status[cell] == CellState.FILLED ||
                status[cell] == CellState.COMPLETED);
    }

    private bool totals_changed () {
        //has number of filled or unknown cells changed?

        bool changed = false;
        int unknown = count_cell_state (CellState.UNKNOWN);
        int filled = count_cell_state (CellState.FILLED);
        int completed = count_cell_state (CellState.COMPLETED);

        if (unknown != this.unknown) {
            changed = true;
            this.unknown = unknown;
            this.filled = filled;

            if (filled + completed > blockTotal) {
                record_error ("totals changed", "too many filled cells");
            } else if (this.unknown == 0) {
                this.is_completed = true;

                if (filled + completed < blockTotal) {
                    record_error ("totals changed", "too few filled cells  - " + filled.to_string ());
                } else {
                    checkNumberOfBlocks ();  //generates its own error
                }
            }
        }

        return changed;
    }

    private void get_status () {
        //transfers cell statuses from grid to internal range status array

        grid.get_array (index, isColumn, ref temp_status);

        for (int i = 0; i < nCells; i++) {

            switch (temp_status[i]) {

                case CellState.EMPTY :
                    if (!tags[i, can_be_empty_pointer]) {
                        record_error ("get_status", "cell " + i.to_string () + " cannot be empty");
                    } else {
                        status[i] = CellState.EMPTY;
                    }

                    break;

                case CellState.FILLED :
                    //dont overwrite COMPLETE status
                    if (status[i] == CellState.EMPTY) {
                        record_error ("get_status", "cell " + i.to_string () + " cannot be filled");
                    }

                    if (status[i] == CellState.UNKNOWN) {
                        status[i] = CellState.FILLED;
                    }

                    break;

                default:
                    break;
            }

            status_to_tags ();
        }
    }

    private void put_status () {
        //use temp_status2 to ovoid overwriting original input  - needed for debugging

        for (int i = 0; i < nCells;  i++) {
            temp_status2[i] = (status[i] == CellState.COMPLETED ? CellState.FILLED : status[i]);
        }

        grid.set_array (index, isColumn, temp_status2);
    }

    private void status_to_tags () {
        for (int i = 0; i < nCells; i++) {

            switch (status[i]) {

                case CellState.COMPLETED:
                    tags[i, is_finished_pointer] = true;
                    tags[i, can_be_empty_pointer] = false;

                    break;

                case CellState.FILLED:
                    tags[i, can_be_empty_pointer] = false;

                    break;

                case CellState.EMPTY:
                    for (int j = 0; j < nBlocks; j++) {
                        tags[i, j] = false;
                    }

                    tags[i, can_be_empty_pointer] = true;
                    tags[i, is_finished_pointer] = true;

                    break;

                default:
                    break;
            }
        }
    }

    private void tags_to_status () {
        for (int i = 0; i < nCells; i++) {
            if (status[i] == CellState.FILLED && tags[i, is_finished_pointer]) {
                status[i] = CellState.COMPLETED;
            }

            if (status[i] != CellState.UNKNOWN) {
                continue;
            }

            if (!tags[i, can_be_empty_pointer]) { //cannot be EMPTY
                status[i] = (tags[i, is_finished_pointer] ? CellState.COMPLETED : CellState.FILLED);
                continue;
            }

            //Can be empty (but not necessarily is empty)
            if (count_possible_owners_and_can_be_empty (i) <= 1) {
                status[i] = CellState.EMPTY;
                tags[i, is_finished_pointer] = true;
            }
        }
    }

    private void record_error (string method, string errmessage, bool debug = true) {
        if (debug) {
            var sb  = new StringBuilder ("");
            sb.append (":  ");
            sb.append (isColumn ? "column" : "row");
            sb.append (index.to_string ());
            sb.append (" in method ");
            sb.append (method);
            sb.append ("\n");
            sb.append (errmessage);
            sb.append (this.to_string ());
            message =   message + sb.str;
        } else {
            in_error = true;
            message = "Record error in " + method + ": " + errmessage + "\n";
        }
    }
}
}
