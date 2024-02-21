/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
/* A region consists of a one dimensional array of cells, corresponding
   to a row or column of the puzzle. Associated with this are:

  1) A list of block lengths (clues)
  2) A boolean array for each cell with
     - a flag for each block indicating whether that block is still a possible owner
     - two extra flags: ' is completed' and ' can be empty'
  3) A boolean array with
    - a flag for each block indicating whether it is completed.
  4) A status array, indicating the status of each cell as either
    - UNKNOWN,
    - FILLED (but not necessarily assigned to a completed block),
    - EMPTY, or
    - COMPLETED (assigned to a completed block).

  5) Can save and restore its state - used to implement  back tracking (one level)
     during trial and error solution ('advanced solver').

  6) Re-used if grid dimensions do not change.
*/

public class Gnonograms.Region {
    public bool is_column { get; private set; }
    public bool in_error { get; private set; default = false; }
    public bool is_completed { get; private set; default = false; }
    public uint index { get; private set; }
    public int n_cells { get; private set; }
    public int block_total { get; private set; } //total cells to be filled
    public string message;

    private uint _value_as_permute_region = uint.MAX;
    public uint value_as_permute_region {
        get {
            if (_value_as_permute_region == uint.MAX) {
                _value_as_permute_region = calc_value_as_permute_region ();
            }

            return _value_as_permute_region;
        }

        set {
            if (_value_as_permute_region < uint.MAX && _value_as_permute_region > 0) {
                _value_as_permute_region = 0;
            }
        }
    }

    private My2DCellArray grid;
    private const int MAXCYCLES = 2;
    private const int FORWARDS = 1;
    private const int BACKWARDS = -1;
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
    private int n_blocks;
    private int block_extent;
    private int can_be_empty_pointer;
    private int is_finished_pointer;
    private int current_index;
    private int current_block_number;
    private int unknown;
    private int unknown_backup;
    private int filled;
    private int filled_backup;
    private int[] blocks;
    private int[,] ranges;
    private int[,] ranges_backup;
    private string clue;
#if WITH_DEBUGGING
    private bool debugging = false;
#endif

    public Region (My2DCellArray grid) {
        this.grid = grid;
        uint max_len = uint.max (grid.rows, grid.cols);
        uint max_blocks = max_len / 2 + 2;
        status = new CellState[max_len];
        status_backup = new CellState[max_len];
        ranges = new int[max_blocks, 4];
        ranges_backup = new int[max_blocks, 4];
        blocks = new int[max_blocks];
        completed_blocks = new bool[max_blocks];
        completed_blocks_backup = new bool[max_blocks];
        tags = new bool[max_len, max_blocks + 2];
        tags_backup = new bool[max_len, max_blocks + 2];
        //two extra flags for "can be empty" and "is finished".
    }

    public void initialize (uint index, bool is_column, uint n_cells, string clue) {
        this.index = index;
        this.is_column = is_column;
        this.n_cells = (int)n_cells;
        this.clue = clue;
        temp_status = new CellState[n_cells];
        temp_status2 = new CellState[n_cells];
        int[] clue_blocks = Utils.block_array_from_clue (clue);
        n_blocks = clue_blocks.length;
        can_be_empty_pointer = n_blocks; //flag for cell that may be empty
        is_finished_pointer = n_blocks + 1; //flag for finished cell (filled or empty?)
        block_total = 0;
        for (int i = 0; i < n_blocks; i++) {
          blocks[i] = clue_blocks[i];
          block_total = block_total + blocks[i];
        }

        block_extent = block_total + n_blocks - 1; //minimum space needed for blocks
        set_to_initial_state ();
        this.is_completed = n_cells == 1; /* Ignore single cell regions (for debugging) */

        _value_as_permute_region = uint.MAX;
    }

    public void set_to_initial_state () {
        for (int i = 0; i < n_blocks; i++) {
          completed_blocks[i] = false;
          completed_blocks_backup[i] = false;
        }

        for (int i = 0; i < n_cells; i++) { //Start with no possible owners and can be empty.
          for (int j = 0; j < n_blocks; j++) {
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
        is_completed = (n_cells == 1); //allows debugging of single row
        if (is_completed) {
            return;
        }

        this.unknown = (int)Gnonograms.MAXSIZE;
        this.filled = (int)Gnonograms.MAXSIZE;
        get_status ();

        if (blocks[0] == 0) { //trivial solution  - complete now
          for (int i = 0; i < n_cells; i++) {
            for (int j = 0; j < n_blocks; j++) {
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
        } else {
            initial_fix ();
        }

        tags_to_status ();
        put_status ();
    }

#if WITH_DEBUGGING
    public bool debug () {
        debugging = true;
        set_to_initial_state ();
        var changed = solve ();
        debugging = false;
        stdout.printf (this.to_string ());
        stdout.printf (message);
        return changed;
    }
#endif

    public bool solve () {
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
         * */
        message = "";
        in_error = false;
        // Get external changes
        get_status ();
        //Is complete or has a (invalid) change been made by another region
        if (in_error) {
            return false;
        }

        // Allow two passes without external changes to ensure all solutions are found
        if (!totals_changed ()) {// checks if completed
            unchanged_count++;
        } else {
            unchanged_count = 0;
        }

        if (is_completed || unchanged_count > 2) {
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
            if (!totals_changed () || in_error) {
                break;
            }

            made_changes = true;
        }

        put_status ();
        return made_changes;
    }

    public void save_state () {
        for (int i = 0; i < n_cells; i++) {
            status_backup[i] = status[i];
            for (int j = 0; j < n_blocks + 2; j++) {
                tags_backup[i, j] = tags[i, j];
            }
        }

        for (int j = 0; j < n_blocks; j++) {
            completed_blocks_backup[j] = completed_blocks[j];
            for (int i = 0; i < 4; i++) {
                ranges_backup[j, i] = ranges[j, i];
            }
        }

        is_completed_backup = this.is_completed;
        filled_backup = this.filled;
        unknown_backup = this.unknown;
    }

    public void restore_state () {
        for (int i = 0; i < n_cells; i++) {
            status[i] = status_backup[i];
            for (int j = 0; j < n_blocks + 2; j++) {
                tags[i, j] = tags_backup[i, j];
            }
        }

        for (int j = 0; j < n_blocks; j++) {
            completed_blocks[j] = completed_blocks_backup[j];
            for (int i = 0; i < 4; i++) {
                ranges[j, i] = ranges_backup[j, i];
            }
        }

        this.is_completed = is_completed_backup;
        this.filled = filled_backup;
        this.unknown = unknown_backup;
        in_error = false;
        message = "";
        unchanged_count = 0;
    }

    public string get_id () {
        string column_or_row;
        var sb = new StringBuilder ("");
        if (is_column) {
            column_or_row = "Column";
        } else {
            column_or_row = "Row";
        }

        sb.append (column_or_row.to_string ());
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
        assert (index < n_cells);
        return status[index] == CellState.COMPLETED ? CellState.FILLED : status[index];
    }

#if WITH_DEBUGGING
    /* For debugging and testing */
    public string to_string () {
        var sb = new StringBuilder ("");
        sb.append (this.get_id ());
        sb.append ("\nstatus before:\n");

        for (int i = 0; i < n_cells; i++) {
            sb.append (i.to_string () + "\t"+ (temp_status[i].to_string () + "\n"));
        }

        sb.append ("\n status now:\n");

        for (int i = 0; i < n_cells; i++) {
            sb.append ((status[i].to_string () + "\n"));
        }

        sb.append ("\nCell Status and Tags:\n");

        for (int i = 0; i < n_cells; i++) {
            sb.append ("Cell " + i.to_string () + " Status: ");
            sb.append (status[i].to_string () + "\nOWNERS ");

            int j;
            for (j = 0; j < n_blocks; j++) {
                if (tags[i, j]) {
                    sb.append ("[%i]".printf (blocks[j]));
                }
            }

            sb.append (" : ");
            if (tags[i, j]) {
                sb.append ("ALLOW EMPTY ");
            }

            j++;
            if (tags[i, j]) {
                sb.append ("COMPLETE");
            }

            sb.append ("\n");
        }

        return sb.str;
    }
#endif

    /** Try and choose more restricted regions to permute to reduce number of possible
      * combinations.
    **/
    private uint calc_value_as_permute_region () {
        if (is_completed) {
            return 0;
        }

        int n_available_ranges = count_available_ranges (false);
        if (n_available_ranges != 1) {
            return 0; //useless as permute region
        }

        int block_extent = 0;
        int count = 0;
        int largest = 0;
        for (int b = 0; b < n_blocks; b++) {
            if (!completed_blocks[b]) {
                block_extent += blocks[b];
                count++;
                largest = int.max (largest, blocks[b]);
            }
        }

        int pvalue = (largest - 1) * block_extent; //block length 1 useless
        if (count == 1) {
            pvalue = pvalue * 2;
        }

        return pvalue;
    }

    private void initial_fix () {
        //finds cells that can be identified as FILLED from the start.
        int freedom = n_cells - block_extent;
        int start = 0, length = 0;

        for (int i = 0; i < n_blocks; i++) {
            length = blocks[i] + freedom;

            for (int j = start; j < start + length; j++) {
                tags[j, i] = true;
            }

            if (freedom < blocks[i]) {
                set_range_owner (i, start + freedom, blocks[i] - freedom, true, false);
            }

            start = start + blocks[i] + 1; //leave a gap between blocks
        }

        if (freedom == 0) {
            is_completed = true;
        }
    }

    private bool full_fix () {
        // Tries each ploy in turn, returns as soon as a change is made
        // or an error detected.

        if (do_edge (1) || in_error) {
            return true;
        }

        if (do_edge ( -1) || in_error) {
            return true;
        }

        if (available_filled_subregion_audit () || in_error) {
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

        if (free_cell_audit () || in_error) {
            return true;
        }

        if (fix_blocks_in_ranges () || in_error) {
            return true;
        }

        if (capped_range_audit () || in_error) {
            return true;
        }

        if (filled_subregion_audit () || in_error) {
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
    bool start_is_capped;
    bool end_is_capped;
    int length;

    current_index = 0;

        while (current_index < n_cells) { //find a filled sub -region
            start_is_capped = false;
            end_is_capped = false;
            current_index = seek_next_required_status (
                CellState.FILLED,
                current_index,
                n_cells,
                1
            );

            if (current_index == n_cells) {
                break;
            }

            //found first FILLED cell; current_index points to it
            if (tags[current_index, is_finished_pointer]) {
                current_index++;
                continue;
            }//ignore if completed already

            if (current_index == 0 || status[current_index - 1] == CellState.EMPTY) {
                start_is_capped = true; //edge cell
            }

            length = count_consecutive_with_state_from (
                CellState.FILLED,
                current_index,
                true //current_index not changed
            );

            // @lastcell: last filled cell in this (partial) block
            int lastcell = current_index + length - 1;
            if (lastcell == n_cells - 1 || status[lastcell + 1] == CellState.EMPTY) {
                end_is_capped = true; //last cell is at edge
            }

            //is this region fully capped?
            if (start_is_capped && end_is_capped) { // assigned block must fit exactly
                assign_and_cap_range (current_index, length);
                current_index += length + 1;
                continue;
            } else { //find largest possible owner of this (partial) block
                int largest = find_largest_possible_block_for_cell (current_index);
                //Test if there is **at least one** largest block that fits exactly
                if (largest == length) {
                    // this region must therefore be complete
                    assign_and_cap_range (current_index, length);
                    current_index += length + 1;
                    changed = true;
                    continue;
                }

                // remove blocks that are smaller than length from this region
                int start = current_index;
                int end = current_index + length - 1; // last filled cell

                for (int bl = 0; bl < n_blocks; bl++) {
                    for (int i = start; i <= end; i++) {

                        if (tags[i, bl] && blocks[bl] < length) {
                            tags[i, bl] = false;
                        }
                    }
                }

                // For the adjacent cells (if not at edge) the minimum length
                // of the owner is one higher.
                if (start > 0) {
                    start--;

                    for (int bl = 0; bl < n_blocks; bl++) {
                        if (tags[start, bl] && blocks[bl] < length + 1) {
                            tags[start, bl] = false;
                        }
                    }
                }

                if (end < n_cells - 1) {
                    end++;

                    for (int bl = 0; bl < n_blocks; bl++) {
                        if (tags[end, bl] && blocks[bl] < length + 1) {
                            tags[end, bl] = false;
                        }
                    }
                }

                if (start_is_capped || end_is_capped) {//semi-capped  - can we extend it?
                  int smallest = find_smallest_possible_block_for_cell (current_index);

                    if (smallest > length) {//can extend by smallest -length away from cap
                        int ptr;

                        if (start_is_capped) {
                          ptr = current_index + length;

                            for (int i = 0; i < smallest - length; i++) {

                                if (ptr < n_cells) {
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

            //move past block  - no operations have been performed on block
            current_index += length;
        }

        return changed;
    }

    private bool fill_gaps () {
        // Find unknown gap between filled cells and complete accordingly.
        bool changed = false;

        for (int idx = 0; idx < n_cells - 2; idx++) {

            if (status[idx] != CellState.FILLED) {
                continue; //find a FILLED cell
            }

            if (status[idx + 1] != CellState.UNKNOWN) {
                    continue; //is following cell empty?
            }

            // if owner ambiguous, can only deal with single cell gap
            if (get_sole_owner (idx) < 0) {
                // see if single cell gap which can be marked empty because
                // to fill it would create a block larger than any permissible.
                if (status[idx + 2] != CellState.FILLED) {
                    continue; //cell after that filled?
                }
                // we have found a one cell gap
                // calculate total length if gap were to be FILLED.
                int block_length = (
                    count_consecutive_with_state_from (
                        CellState.FILLED, idx + 2, true
                    ) +
                    count_consecutive_with_state_from (
                        CellState.FILLED, idx, false
                    ) + 1
                );

                bool must_be_empty = true;

                //look for a possible owner at least as long as combined length
                for (int bl = 0; bl < n_blocks; bl++) {
                    //If possible owner found  - gap could be filled
                    if (tags[idx, bl] && blocks[bl] >= block_length) {
                        must_be_empty = false;
                        break;
                    }
                }

                //no permissible blocks large enough
                if (must_be_empty) {
                    set_cell_empty (idx + 1);
                    changed = true;
                } else {
                    // see if setting empty would create two regions one or more of which
                    // is too small for the available blocks
                    bool must_not_be_empty = false;
                    int length_to_the_left = 0, length_to_the_right = 0;
                    int ptr = idx;

                    //left-hand region
                    while (ptr >= 0 && !tags[ptr, is_finished_pointer]) {
                        ptr--;
                        length_to_the_left++;
                    }

                    ptr = idx + 2;

                    //right-hand region
                    while (ptr < n_cells && !tags[ptr, is_finished_pointer]) {
                        ptr++;
                        length_to_the_right++;
                    }

                    //find largest, earliest possible block fitting in first range
                    int count_to_the_left = 0;
                    int count_to_the_right = 0;
                    int total_count;

                    ptr = idx; //cell before gap

                    for (int i = 0; i < n_blocks; i++) {
                        if (tags[ptr, i] && blocks[i] <= length_to_the_left) {
                            count_to_the_left++;
                        }
                    }

                    ptr = idx + 2; //cell after gap

                    for (int i = 0; i < n_blocks; i++) {
                        if (tags[ptr, i] && blocks[i] <= length_to_the_right) {
                            count_to_the_right++;
                        }
                    }

                    total_count = count_to_the_left + count_to_the_right;

                    if (total_count == 2) {
                        for (int i = 0; i < n_blocks; i++) {
                            if (tags[ptr, i] && blocks[i] <= length_to_the_right) {
                                if (tags[idx, i] && blocks[i] <= length_to_the_left) {
                                    // only one block fits in both sides
                                    must_not_be_empty = true;
                                }
                            }
                        }
                    } else if (total_count < 2) {
                        must_not_be_empty = true;
                    }

                    if (must_not_be_empty) {
                        tags[idx + 1, can_be_empty_pointer] = false;
                        changed = true;
                    }
                }

                idx += 2; //skip gap
            } else {
                //only one possible owner of first FILLED cell
                int cell1 = idx; //start of gap
                idx++;

                //skip to end of gap
                while (idx < n_cells - 1 && status[idx] == CellState.UNKNOWN) {
                    idx++;
                }

                if (status[idx] != CellState.FILLED) {
                    continue; //gap ends with empty cell  - abandon this gap
                } else { //if start and end of gap have same owner, fill in the gap.
                    int owner = have_same_owner (cell1, idx);
                    if (owner >= 0) {
                        changed = changed || set_range_owner (
                            owner, cell1, idx - cell1 + 1, true, false
                        );
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

        for (int i = 0; i < n_blocks; i++) {

            if (completed_blocks[i]) {
                continue; //skip completed block
            }

            start = 0;
            length = 0;
            count = 0; //how many possible ranges for this block

            for (int idx = 0; idx < n_cells; idx++) {

                if (count > 1) {
                    break; //no unique range  - try next block
                }

                if (!tags[idx, i] || tags[idx, is_finished_pointer]) {
                    continue; //cell not possible for this block or already completed
                }

                int s = idx; //first cell with block i as possible owner
                //length of contiguous cells having this block (i) as a possible owner.
                int l = count_contiguous_with_same_owner_from (i, idx);

                if (l < blocks[i]) {
                    remove_block_from_range (i, s, l, 1); //block cannot be here
                } else {
                    length = l;
                    start = s;
                    count++;
                }

                idx += (l - 1); //allow for incrementing on next loop
            }

            if (count != 1) {
                continue; //no unique range found
            } else { //perhaps some cells can be assigned but
                //this range not proved exclusive to this block;
                changed = fix_block_in_range (i, start, length) || changed;
            }
        }

        return changed;
    }

    private void assign_and_cap_range (int start, int length) {
        //make list of possible blocks with right length in max_blocks[]
        //record which is first and which last (in order).
        //always changes at least one cell status

        int count = 0;
        int[] max_blocks = new int[n_blocks];
        int first = n_blocks;
        int last = 0;
        int end = start + length - 1;

        for (int i = 0; i < n_blocks; i++) {
            if (completed_blocks[i]) {
                continue;
            }

            if (blocks[i] != length) {
                continue;
            }

            if (!tags[start, i] || !tags[end, i]) {
                continue;
            }

            max_blocks[count] = i;
            count++;

            if (i < first) {
                first = i;
            }

            if (i > last) {
                last = i;
            }
        }

        if (count == 0) {
            return; //no matching block  - range is not complete
        }

        if (count == 1) { //unique owner
            set_block_complete_and_cap (max_blocks[0], start, 1);
        } else { //ambiguous owner
            //delete out of sequence blocks before end of range
            for (int i = last + 1; i < n_blocks; i++) {
                remove_block_from_cell_to_end (i, start + length - 1, -1);
            }

            //delete out of sequence blocks after start of range
            for (int i = 0; i < first; i++) {
                remove_block_from_cell_to_end (i, start, 1);
            }

            //remove as possible owner blocks between first and last that are wrong length
            for (int i = first + 1; i < last; i++) {
                if (blocks[i] == length) {
                    continue;
                }

                remove_block_from_range (i, start, length, 1);
            }

            //for each possible mark as possible owner of subregion (not exclusive)
            for (int i = 0; i < count; i++) {
                set_range_owner (max_blocks[i], start, length, false, false);
            }

            // cap range
            if (start > 0) {
                set_cell_empty (start - 1);
            }

            if (start + length < n_cells) {
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

        for (int i = 0; i < n_cells; i++) {
            if (tags[i, is_finished_pointer]) {
                continue;
            }

            // unfinished cell found
            if (status[i] == CellState.FILLED) {
                owner = get_sole_owner (i);
                if (owner >= 0) { //cell is FILLED and has only one owner
                    length = blocks[owner];
                    //remove this block from earlier cells our of range
                    start = i - length;
                    if (start >= 0) {
                        remove_block_from_cell_to_end (owner, start, BACKWARDS);
                    }

                    //remove this block from later cells our of range
                    start = i + length;
                    if (start < n_cells) {
                        remove_block_from_cell_to_end (owner, start, FORWARDS);
                    }
                }
            }
        }

        return false; //always false  - only changes tags
    }

    private bool free_cell_audit () {
        // Compare  number of UNKNOWN cells with the number of unassigned
        // block cells.
        // If they are the same then mark all UNKNOWN cells as
        // FILLED and mark all blocks COMPLETE.
        // If there are no unassigned block cells then mark all UNKNOWN
        // cells as EMPTY.

        int free_cells = count_cell_state (CellState.UNKNOWN);

        if (free_cells == 0) {
            return false;
        }

        int filled_cells = count_cell_state (CellState.FILLED);
        int completed_cells = count_cell_state (CellState.COMPLETED);
        int to_be_located = block_total - filled_cells - completed_cells;

        if (free_cells == to_be_located) { // Set all UNKNOWN as COMPLETE
            for (int i = 0; i < n_cells; i++) {
                if (status[i] == CellState.UNKNOWN || status[i] == CellState.FILLED) {
                    set_cell_complete (i);
                }
            }

            for (int i = 0; i < n_blocks; i++) {
                completed_blocks[i] = true;
            }

            return true;
        } else if (to_be_located == 0) {
            for (int i = 0; i < n_cells; i++) {

                if (status[i] == CellState.UNKNOWN) {
                    set_cell_empty (i);
                }

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
            limit = n_cells;
        } else {
            current_index = n_cells - 1;
            current_block_number = n_blocks - 1;
            limit = -1;
        }

        //Find first edge - skipping completed cells
        if (!find_edge (limit, direction)) {
            return false;
        }

        //current_index points to cell on the edge
        if (status[current_index] == CellState.FILLED) {
            //first cell is FILLED. Can complete whole block
            return set_block_complete_and_cap (
                current_block_number,
                current_index,
                direction
            );
        } else { // see if filled cell in range of first block and complete after that
            int start_of_edge = current_index;
            int start_of_filling = -1;
            int block_length = blocks[current_block_number];
            int blocklimit = dir?
                             current_index + block_length :
                             current_index - block_length;

            if (blocklimit < -1 && blocklimit > n_cells) {
                in_error = true;
                message = "Invalid blocklimit";
                return false;
            }

            current_index = seek_next_required_status (
                CellState.FILLED,
                current_index,
                blocklimit,
                direction
            );

            if (current_index != blocklimit) {
                start_of_filling = current_index;
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

                while (current_index != blocklimit &&
                       status[current_index] == CellState.FILLED
                ) {
                    set_cell_owner (current_index, current_block_number, true, false);
                    set_cell_empty (start_of_edge);
                    changed = true;

                    if (dir) {
                        current_index++;
                        start_of_edge++;
                    } else {
                        current_index--;
                        start_of_edge--;
                    }
                }

                //if a fillable cell was found then start_of_filling > 0
                if (start_of_filling > 0) {
                    //delete block more than block length from where filling started
                    current_index = start_of_filling + (dir ? block_length : -block_length);

                    if (current_index >= 0 && current_index < n_cells) {
                        remove_block_from_cell_to_end (
                            current_block_number,
                            current_index,
                            direction
                        );
                    }
                }

                return changed;
            }
        }

        return false;
    }

    private bool find_edge (int limit, int direction) {
        // Edge is first FILLED or UNKNOWN cell from limit of region.
        //starting point is set in current_index and current_block_number before calling.
        bool dir = (direction == FORWARDS);
        int loop_step = dir ? 1 : -1;
        for (int i = current_index; (i >= 0 && i < n_cells); i += loop_step) {
            if (status[i] == CellState.EMPTY) {
                continue;
            }

            //now pointing at first cell of filled or unknown block after edge
            if (tags[i, is_finished_pointer]) { //skip to end of finished block
                i += (dir ?
                      blocks[current_block_number] - 1 :
                      1 - blocks[current_block_number]
                );
                //now pointing at last cell of filled block
                var next_block = current_block_number + loop_step;
                //Increment or decrement current block as appropriate
                if (next_block >= 0 || next_block < n_blocks - 1) {
                    current_block_number = next_block;
                } else {
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
        int[] available_blocks = get_blocks_available ();
        int bl = available_blocks.length;
        if (bl == 0) {
            return false;
        }

        // update ranges with currently available ranges
        // (can contain only unknown  and incomplete cells)
        int n_available_ranges = count_available_ranges (false);
        if (n_available_ranges == 0) {
            return false;
        }

        //range number and offset of earliest start point
        int[,] block_start = new int[bl, 2];
        //range number and offset of latest end point
        int[,] block_end = new int[bl, 2];
        //find earliest start point of each block (treating ranges as all unknown cells)
        int rng = 0;
        int offset = 0;
        int length = 0;
        int ptr = 0;
        int start = 0;

        for (int b = 0; b < bl; b++) {//for each available block
            length = blocks[available_blocks[b]]; //get its length
            if (ranges[rng, 1] < (length + offset)) {//cannot fit in current range
                rng++;
                offset = 0; //skip to start of next range
                while (rng < n_available_ranges && ranges[rng, 1] < length) {
                    rng++; //keep skipping if too small
                }

                if (rng >= n_available_ranges) {
                    return false;
                }
            }

            //look for collision with filled cell
            ptr = ranges[rng, 0] + offset + length; //cell after end of block
            start = ptr;
            while (ptr < n_cells && !tags[ptr, can_be_empty_pointer]) {
                ptr++;
                offset++;
            }

            block_start[b, 0] = rng; //set start range number
            block_start[b, 1] = offset; //and start point
            offset += (length + 1); //move offset allowing for one cell gap between blocks
        }

        //carry out same process in reverse to get latest end points
        rng = n_available_ranges - 1;
        offset = 0; //start at end of last range NB offset now counts from end
        for (int b = bl - 1; b >= 0; b--) { //start at last block
            length = blocks[available_blocks[b]]; //get length
            if (ranges[rng, 1] < (length + offset)) { //doesn't fit
                rng --;
                offset = 0;
                while (rng >= 0 && ranges[rng, 1] < length) {
                    rng --; //keep skipping if too small
                }

                if (rng < 0) {
                    return false;
                }
            }

            //look for collision with filled cell
            //cell before beginning of block
            ptr = ranges[rng, 0] + ranges[rng, 1] - (offset + length) - 1;
            start = ptr;
            while (ptr >= 0 && !tags[ptr, can_be_empty_pointer]) {
                ptr --;
                offset++;
            }

            block_end[b, 0] = rng; //set end range number
            block_end[b, 1] = ranges[rng, 1] - offset; //and end point
            //NB end point is index of cell AFTER last possible cell so that
            //subtracting start from end gives length of range.
            offset += (length + 1); //shift offset allowing for one cell gap
        }

        for (int b = 0; b < bl; b++) { //for each available block
            rng = block_start[b, 0];
            offset = block_start[b, 1];
            start = ranges[rng, 0];

            if (rng == block_end[b, 0]) { //if starts and ends in same range
                length = block_end[b, 1] - block_start[b, 1];
                //'length' now used for total length of possible range for this block
                fix_block_in_range (available_blocks[b], start + offset, length);
            }

            //remove block from outside possible range
            if (offset > 1) {
                remove_block_from_range (available_blocks[b], start, offset - 1, 1);
            }

            for (int r = 0; r < block_start[b, 0]; r++) { //ranges before possible
                remove_block_from_range (available_blocks[b], ranges[r, 0], ranges[r, 1], 1);
            }

            rng = block_end[b, 0];
            start = ranges[rng, 0] + block_end[b, 1];
            length = ranges[rng, 1] - block_end[b, 1];

            if (length > 0) {
                remove_block_from_range (available_blocks[b], start, length, 1);
            }

            //ranges after possible
            for (int r = n_available_ranges - 1; r > block_end[b, 0]; r--) {
                remove_block_from_range (available_blocks[b], ranges[r, 0], ranges[r, 1], 1);
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
        int n_ranges = count_capped_ranges ();

        if (n_ranges == 0) {
            return false;
        }

        for (int rng = 0; rng < n_ranges; rng++) {
            start = ranges[rng, 0];
            length = ranges[rng, 1];
            for (idx = start; idx < start + length; idx++) {
                int count = 0;
                int impossible = 0;
                for (int b = 0; b < n_blocks; b++) {
                    if (tags[idx, b]) {
                        count++;
                        if (blocks[b] != length) {
                            tags[idx, b] = false;
                            impossible++;
                        }
                    }
                }

                if (count == impossible) {
                    record_error (
                        "capped range audit",
                        "start %i len %i, n_blocks %u count %i, impossible %i filled cell with no owners".printf (
                            start, length, n_blocks, count, impossible
                        )
                    );
                    return false;
                }
            }
        }

        return false;
    }

    private bool available_filled_subregion_audit () {
        //test whether there is an unambiguous distribution of available blocks
        //amongst available filled subregions.

        int idx = 0;
        int start = 0;
        int end = n_cells;
        int region_count = 0;
        //start and end of each subregion
        Range[] available_subregions = new Range[n_cells / 2];
        while (idx < n_cells) {
            if (status[idx] != CellState.FILLED) {
                idx++;
                continue;
            }

            region_count++;
            if (region_count <= n_blocks) {
                start = idx;
            } else {
                return false;
            }

            while (idx < n_cells && status[idx] == CellState.FILLED) {
                idx++;
            }

            end = idx - 1; //last filled cell
            available_subregions[region_count - 1] = Range () {
                start = start,
                end = end,
                filled = -1,
                unknown = -1
            };
        }

        if (region_count < 2 || region_count > n_blocks) {
            return false;
        }

        //now see how many blocks could fit here;
        int[] available_blocks = get_blocks_available ();
        int n_available_blocks = available_blocks.length;
        if (region_count > n_available_blocks) {
            return false;
        }

        int first_start = available_subregions[0].start;
        int length = available_subregions[0].length ();
        int last_end = available_subregions[region_count - 1].end;

        //delete available blocks up to first in the first subregion
        int block_count = n_available_blocks;
        int bl;

        for (int i = 0; i < n_available_blocks; i++) {
            bl = available_blocks[i];
            if (!tags[first_start, bl]) {
                available_blocks[i] = -1;
                block_count --;
            } else {
                break;
            }
        }

        for (int i = n_available_blocks - 1; i >= 0; i --) {
            bl = available_blocks[i];
            if (bl >= 0 && !tags[last_end, bl]) {
                available_blocks[i] = -1;
                block_count --;
            } else {
                break;
            }
        }

        if (block_count != region_count) {
            return false;
        }

        int[] candidates = new int[block_count];
        int candidates_count = 0;
        int combined_length = 0;
        for (int i = 0; i < n_available_blocks; i++) {
            if (available_blocks[i] < 0) {
                continue;
            } else {
                candidates[candidates_count] = available_blocks[i];
                combined_length += blocks[available_blocks[i]];
                candidates_count++;
            }
        }

        //allow for gap of at least 1 between blocks
        combined_length += (candidates_count - 1);

        // for unambiguous assignment, all sub regions must be separated by more than
        // the combined length of the candidate blocks and gaps
        int overall_length = last_end - first_start + 1;
        if (overall_length < combined_length) {
            return false;
        }

        //consecutive regions must be separated so one block cannot cover both
        //either by finished cell or by distance
        for (int ar = 0; ar < region_count - 1; ar++) {
            var regions_are_separate = false;
            for (int i = available_subregions[ar].end; i < available_subregions[ar + 1].start; i++) {
                if (tags[i, is_finished_pointer]) {
                    regions_are_separate = true;
                    break;
                }
            }

            if (regions_are_separate) {
                continue; //separated by empty or complete cell
            } else {
                start = available_subregions[ar].start;
                end = available_subregions[ar + 1].end;
                length = end - start + 1;
                if (length <= blocks[candidates[ar]] || length <= blocks[candidates[ar + 1]]) {
                    return false; //too close
                }
            }
        }

        //Unambiguous assignment possible
        if (region_count > candidates_count) {
            in_error = true;
            message = "region_count > candidates_count";
            return false;
        }

        for (int ar = 0; ar < region_count; ar++) {
            bl = candidates[ar];
            length = blocks[bl];
            set_range_owner (bl, available_subregions[ar].start, available_subregions[ar].length (), true, false);
        }

        return false; //only changes tags
    }


    // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==
    // END OF PLOYS
    // HELPER FUNCTIONS FOLLOW
    // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==

    private int seek_next_required_status (int cs, int idx, int limit, int direction) {
        // increments/decrements idx until cell of required state
        // or end of range found.
        // returns idx of cell with status cs if found else limit
        if (limit < -1 || limit > n_cells) {
            in_error = true;
            message = "limit < -1 || limit > n_cells";
            return 0;
        }

        if ((direction == Region.FORWARDS) && idx >= limit) {
            return limit;
        } else if ((direction == Region.BACKWARDS) && (idx <= limit)) {
            return limit;
        }

        for (int i = idx; i != limit; i += direction) {
            if (status[i] == cs) {
                return i;
            }
        }

        return limit; //false;
    }

    private int count_consecutive_with_state_from (int cs, int idx, bool forwards) {
        // count how may consecutive cells of state cs starting at given
        // index idx (inclusive of starting cell)
        int count = 0;
        if (forwards && idx >= 0) {
            while (idx < n_cells && status[idx] == cs) {
                count++;
                idx++;
            }
        } else if (!forwards && idx < n_cells) {
            while (idx >= 0 && status[idx] == cs) {
                count++;
                idx--;
            }
        } else {
            in_error = true;
            message = "count_consecutive_with_state_from";
        }

        return count;
    }

    private int count_contiguous_with_same_owner_from (int owner, int idx) {
        // count how may consecutive cells with owner possible starting
        // at given index idx?
        int count = 0;
        if (idx >= 0) {
            while (idx < n_cells && tags[idx, owner] && !tags[idx, is_finished_pointer]) {
                count++;
                idx++;
            }
        } else {
            in_error = true;
            message = "count_contiguous_with_same_owner_from";
        }

        return count;
    }

    private int count_available_ranges (bool notempty) {
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
        while (idx < n_cells && tags[idx, is_finished_pointer]) {
            idx++;
        }

        while (idx < n_cells) {
            length = 0;
            start = idx;
            ranges[range, 0] = start;
            ranges[range, 2] = 0;
            ranges[range, 3] = 0;
            while (idx < n_cells && !tags[idx, is_finished_pointer]) {
                if (!tags[idx, can_be_empty_pointer]) {
                    ranges[range, 2]++; //FILLED
                } else {
                    ranges[range, 3]++; //UNKNOWN
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

            while (idx < n_cells && tags[idx, is_finished_pointer]) {
                idx++;
            }
        }

        return range; //number of ranges  - not last index!
    }

    private bool match_clue () {
        //only called when region is completed. Checks whether number of blocks is correct
        int count = 0, idx = 0, blk_ptr = 0, blk_counter = 0;
        while (idx < n_cells) {
            while (idx < n_cells && status[idx] == CellState.EMPTY) {
                idx++;
            }

            if (idx < n_cells) {
                count++;
            } else {
                break;
            }

            while (idx < n_cells && status[idx] != CellState.EMPTY) {
                blk_counter++;
                idx++;
            }

            if (blocks[blk_ptr] != blk_counter) {
                return false;
            } else {
                blk_ptr++;
                blk_counter=0;
            }
        }

        if (count != n_blocks) {
          record_error ("Check n_blocks",
                        "Wrong number of blocks found. %i should be %i"
                        .printf (count, n_blocks));

          return false;
        } else {
            return true;
        }
    }

    private int count_capped_ranges () {
        // determine location of capped ranges of filled cells (not marked complete) and store in ranges[, ]
        int range = 0;
        int start = 0;
        int length = 0;
        int idx = 0;
        while (idx < n_cells && status[idx] != CellState.FILLED) {
            idx++; //skip to beginning of first range
        }

        while (idx < n_cells) {
            length = 0;
            start = idx;
            ranges[range, 0] = start;
            ranges[range, 2] = 0; //not used
            ranges[range, 3] = 0; //not used
            while (idx < n_cells && status[idx] == CellState.FILLED) {
                idx++;
                length++;
            }

            if ((start == 0 || status[start - 1] == CellState.EMPTY) &&
                (idx == n_cells || status[idx] == CellState.EMPTY)
            ) { //capped
                ranges[range, 1] = length;
                range++;
            }

            idx++;
            while (idx < n_cells && status[idx] != CellState.FILLED) {
                idx++; //skip to beginning of next range
            }
        }

        return range;
    }

    private int count_possible_owners_and_can_be_empty (int cell) {
        // how many possible owners?  Does include can be empty tag!
        int count = 0;
        if (is_invalid_data (cell)) {
            in_error = true;
            message = "count_possible_owners_and_can_be_empty 1";
        } else {
            for (int j = 0; j < n_blocks; j++) {
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
            message = "count_possible_owners_and_can_be_empty 2";
        }

        return count;
    }

    private int count_cell_state (int cs) {
        //how many times does state cs occur in range.
        int count = 0;
        for (int i = 0; i < n_cells; i++) {
            if (status[i] == cs) {
                count++;
            }
        }

        return count;
    }

    private int[] get_blocks_available () {
        //array of incomplete block indexes
        int[] blocks = {};
        for (int i = 0; i < n_blocks; i++) {
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
        if (cell1 < 0 || cell1 >= n_cells || cell2 < 0 || cell2 >= n_cells) {
            in_error = true;
            message = "have_same_owner";
        } else {
            for (int i = 0; i < n_blocks; i++) {
                tmp = tags[cell1, i];
                if (count > 1 || (tmp != tags[cell2, i])) {
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

    private int get_sole_owner (int cell) {
        // if only one possible owner (if not empty) then return owner index
        // else return -1.
        int count = 0;
        int owner = -1;
        for (int i = 0; i < n_blocks; i++) {
            if (tags[cell, i]) {
                owner = i;
                count++;
            }

            if (count > 1) {
                break;
            }
        }

        return count == 1 ? owner : -1;
    }

    private bool fix_block_in_range (int block, int start, int length) {
        // block must be limited to range
        var changed = false;
        if (is_invalid_data (start, block, length)) {
            in_error = true;
            message = "fix_block_in_range";
        } else {
            int blocklength = blocks[block];
            int freedom = length - blocklength;
            if (freedom < 0) {
                record_error ("Fix block in range", "block longer than range");
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
        for (int i = 0; i < n_blocks; i++) {
            if (!tags[cell, i]) {
                continue; // not possible
            }

            if (blocks[i] <= maxsize) {
                continue; // not largest
            }

            maxsize = blocks[i]; //update largest
        }

        return maxsize;
    }

    private int find_smallest_possible_block_for_cell (int cell) {
        // find the smallest incomplete block possible for given cell
        int minsize = 9999;
        for (int i = 0; i < n_blocks; i++) {
            if (!tags[cell, i]) {
                continue; // not possible
            }

            if (blocks[i] >= minsize) {
                continue; // not largest
            }

            minsize = blocks[i]; //update largest
        }

        if (minsize == 9999) {
            record_error ("findsmallest possible in cell", "No block possible in " + cell.to_string ());
            return 0;
        }

        return minsize;
    }

    private void remove_block_from_cell_to_end (int block, int start, int direction) {
        //remove block as possibility after/before start
        //bi-directional forward = 1 backward  = -1
        //if reverse direction then equivalent forward range is used
        //only changes tags
        int length = direction > 0 ? n_cells - start : start + 1;
        start = direction > 0 ? start : 0;
        if (length > 0) {
            remove_block_from_range (block, start, length, 1);
        }
    }

    private void remove_block_from_range (int block, int start, int length, int direction) {
        //remove block as possibility in given range
        //bi-directional forward = 1 backward  = -1
        //if reverse direction then equivalent forward range is used
        //only changes tags
        if (direction < 0) {
            start = start - length + 1;
        }

        if (is_invalid_data (start, block, length)) {
            in_error = true;
            message = "remove_block_from_range";
        } else {
            for (int i = start; i < start + length; i++) {
                tags[i, block] = false;
            }
        }
    }

    private bool set_block_complete_and_cap (int block, int start, int direction) {
        //returns true  - always changes a cell status if not in error
        bool changed = false;
        int length = blocks[block];
        if (direction < 0) {
            start = start - length + 1;
        }

        if (is_invalid_data (start, block, length)) {
            in_error = true;
            message = "set_block_complete_and_cap 1";
            return false;
        }

        if (completed_blocks[block] == true && tags[start, block] == false) {
            in_error = true;
            message = "set_block_complete_and_cap 2";
            return false;
        }

        completed_blocks[block] = true;
        set_range_owner (block, start, length, true, false);
        if (start > 0 && !tags[start - 1, is_finished_pointer]) {
            changed = true;
            set_cell_empty (start - 1);
        }

        if (start + length < n_cells && !tags[start + length, is_finished_pointer]) {
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
                l = l + blocks[bl + 1] + 1; // length of exclusion zone for this block
                remove_block_from_range (bl, start - 2, l, -1);
            }
        }

        // constrain the following blocks if there are at least two
        if (block < n_blocks - 2) {
            l = 0;
            for (int bl = block + 2; bl <= n_blocks - 1; bl++) {
                l = l + blocks[bl - 1] + 1; // length of exclusion zone for this block
                remove_block_from_range (bl, start + length + 1, l, 1);
            }
        }

        return changed; //if block was not already capped
    }

    private bool set_range_owner (int owner, int start, int length, bool exclusive, bool can_be_empty) {
        bool changed = false;
        if (is_invalid_data (start, owner, length)) {
            in_error = true;
            message = "set_range_owner 1";
            return false;
        } else {
            int blocklength = blocks[owner];
            for (int cell = start; cell < start + length; cell++) {
                set_cell_owner (cell, owner, exclusive, can_be_empty);
            }

            if (exclusive) {
                //remove block and out of sequence from regions out of reach if exclusive
                if (blocklength < length && !can_be_empty) {
                    in_error = true;
                    message = "set_range_owner 2";
                    return false;
                }

                int bstart = int.min (start - 1, start + length - blocklength);
                if (bstart >= 0) {
                    remove_block_from_cell_to_end (owner, bstart - 1, -1);
                }

                int bend = int.max (start + length, start + blocklength);
                if (bend < n_cells) {
                    remove_block_from_cell_to_end (owner, bend, 1);
                }

                int earliestend = start + length;
                for (int bl = n_blocks - 1; bl > owner; bl --) { //following blocks cannot be earlier
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

    private bool set_cell_owner (int cell, int owner, bool exclusive, bool can_be_empty) {
        //exclusive  - cant be any other block here
        //can be empty  - self evident
        bool changed = false;
        if (is_invalid_data (cell, owner)) {
            record_error (
                "set_cell_owner",
                "invalid data %i, %i, %s, %s".printf (
                    cell, owner, exclusive.to_string (), can_be_empty.to_string ()
                )
            );
        } else if (status[cell] == CellState.EMPTY) {// do nothing  - not necessarily an error
        } else if (status[cell] == CellState.COMPLETED && tags[cell, owner] == false) {
            record_error (
                "set_cell_owner",
                "contradiction cell " + cell.to_string () + " filled but cannot be owner"
            );
        } else {
            if (exclusive) {
                for (int i = 0; i < n_blocks; i++) {
                    tags[cell, i] = false;
                }
            }

            if (!can_be_empty) {
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
            for (int i = 0; i < n_blocks; i++) {
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
                start >= n_cells ||
                length < 0 ||
                start + length > n_cells ||
                block < 0 ||
                block >= n_blocks);
    }

    private bool is_cell_filled (int cell) {
        return (status[cell] == CellState.FILLED ||
                status[cell] == CellState.COMPLETED);
    }

    private bool totals_changed () {
        //has number of filled or unknown cells changed?
        bool changed = false;
        int _unknown = count_cell_state (CellState.UNKNOWN);
        int _filled = count_cell_state (CellState.FILLED);
        int _completed = count_cell_state (CellState.COMPLETED);
        if (_unknown != this.unknown) {
            changed = true;
            this.unknown = _unknown;
            this.filled = _filled;
            if (_filled + _completed > block_total) {
                record_error (
                    "totals changed",
                    "too many filled cells filled %i, completed %i, block total %i".printf (
                        _filled, _completed, block_total
                    )
                );

            } else if (this.unknown == 0) {
                if (_filled + _completed < block_total) {
                    record_error (
                        "totals changed",
                        "too few filled cells filled %i, completed %i, block total %i".printf (
                            _filled, _completed, block_total
                        )
                    );
                } else if (match_clue ()) {
                    this.is_completed = true;
                } else {
                    in_error = true;
                    message = "totals_changed";
                    return false;
                }
            }
        }

        return changed;
    }

    private void get_status () {
        //transfers cell statuses from grid to internal range status array
        grid.get_array (index, is_column, ref temp_status);
        for (int i = 0; i < n_cells; i++) {
            switch (temp_status[i]) {
                case CellState.EMPTY :
                    if (!tags[i, can_be_empty_pointer]) {
                        record_error (
                            "get_status",
                            "cell " + i.to_string () + " cannot be empty"
                        );
                    } else {
                        status[i] = CellState.EMPTY;
                    }

                    break;
                case CellState.FILLED :
                    //dont overwrite COMPLETE status
                    if (status[i] == CellState.EMPTY) {
                        record_error (
                            "get_status",
                            "cell " + i.to_string () + " cannot be filled"
                        );
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
        for (int i = 0; i < n_cells; i++) {
            temp_status2[i] = status[i] == CellState.COMPLETED ?
                              CellState.FILLED : status[i];
        }

        grid.set_array (index, is_column, temp_status2);
    }

    private void status_to_tags () {
        for (int i = 0; i < n_cells; i++) {
            switch (status[i]) {
                case CellState.COMPLETED:
                    tags[i, is_finished_pointer] = true;
                    tags[i, can_be_empty_pointer] = false;

                    break;
                case CellState.FILLED:
                    tags[i, can_be_empty_pointer] = false;

                    break;
                case CellState.EMPTY:
                    for (int j = 0; j < n_blocks; j++) {
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
        for (int i = 0; i < n_cells; i++) {
            if (status[i] == CellState.FILLED && tags[i, is_finished_pointer]) {
                status[i] = CellState.COMPLETED;
            }

            if (status[i] != CellState.UNKNOWN) {
                continue;
            }

            if (!tags[i, can_be_empty_pointer]) { //cannot be EMPTY
                status[i] = tags[i, is_finished_pointer] ?
                            CellState.COMPLETED : CellState.FILLED;
                continue;
            }

            //Can be empty (but not necessarily is empty)
            if (count_possible_owners_and_can_be_empty (i) <= 1) {
                status[i] = CellState.EMPTY;
                tags[i, is_finished_pointer] = true;
            }
        }
    }

    private void record_error (string method, string errmessage) {
        in_error = true;
        message = "%s Region %u Record error in %s : %s \n".printf (
            is_column ? "COL" : "ROW", index, method, errmessage
        );
    }
}
