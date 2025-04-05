/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2010-2024 Jeremy Wootten
 *
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>
 */
public class Gnonograms.My2DCellArray : Object {
    public uint rows { get; construct; }
    public uint cols { get; construct; }
    public uint area { get; construct; }

    private CellState[,] data;

    public My2DCellArray (Dimensions _dimensions, CellState init = CellState.EMPTY) {
        Object (
            rows: _dimensions.height,
            cols: _dimensions.width,
            area: _dimensions.area ()
        );

        set_all (init);
    }

    construct {
        data = new CellState[rows, cols];
    }

    public void set_data_from_cell (Cell c) {
        data[c.row, c.col] = c.state;
    }

    public void set_data_from_rc (uint r, uint c, CellState s) {
        data[r, c] = s;
    }

    public CellState get_data_for_cell (Cell cell) {
        return data[cell.row, cell.col];
    }

    public CellState get_data_from_rc (uint r, uint c) {
        return data[r, c];
    }

    public void get_row (uint row, ref CellState[] sa, uint start = 0) {
        for (uint c = start; c < start + sa.length; c++) {
            sa[c] = data[row,c];
        }
    }

    public void set_row (uint row, CellState[] sa, uint start = 0) {
        for (uint c = 0; c < sa.length; c++) {
            data[row, c + start] = sa[c];
        }
    }

    public void get_col (uint col, ref CellState[] sa, uint start = 0) {
        for (uint r = start; r < start + sa.length; r++) {
            sa[r] = data[r, col];
        }
    }

    public void set_col (uint col, CellState[] sa, uint start = 0) {
        for (uint r = 0; r < sa.length; r++) {
            data[r + start, col] = sa[r];
        }
    }

    public void get_array (uint idx, bool iscolumn, ref CellState[] sa, uint start = 0) {
        if (iscolumn) {
            get_col (idx, ref sa, start);
        } else {
            get_row (idx, ref sa, start);
        }
    }

    public void set_array (uint idx, bool iscolumn, CellState[] sa, uint start = 0) {
        if (iscolumn) {
            set_col (idx, sa, start);
        } else {
            set_row (idx, sa, start);
        }
    }

    public void set_all (CellState s) {
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                data[r,c] = s;
            }
        }
    }

    public int count_state (CellState cell_state) {
        CellState cs;
        int count = 0;
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                cs = get_data_from_rc (r, c);
                if (cs == cell_state) {
                    count++;
                }
            }
        }

        return count;
    }

    public string data2text (uint idx, uint length, bool iscolumn) {
        CellState[] arr = new CellState[length];
        this.get_array (idx, iscolumn, ref arr);
        return Utils.block_string_from_cellstate_array (arr);
    }

    public void copy (My2DCellArray ca) {
        for (uint r = 0; r < uint.min (ca.rows, this.rows); r++) {
            for (uint c = 0; c < uint.min (ca.cols, this.cols); c++) {
                data[r,c] = ca.get_data_from_rc (r, c);
            }
        }
    }

    public string to_string () {
        StringBuilder sb = new StringBuilder ();
        CellState[] arr = new CellState[cols];
        for (int r = 0; r < rows; r++) {
            get_row (r, ref arr);
            sb.append (Utils.string_from_cellstate_array (arr));
            sb.append ("\n");
        }

        return sb.str;
    }

    public Iterator iterator () {
        return new Iterator (data, rows, cols);
    }

    public class Iterator {
        private CellState [ , ] data;
        private uint row_limit;
        private uint col_limit;
        private uint row_index = 0;
        private uint col_index = 0;

        public Iterator (CellState [,] _data, uint rows, uint cols) {
            this.data = _data;
            row_limit = rows - 1;
            col_limit = cols - 1;
        }

        public bool next () {
            return col_index <= col_limit;
        }

        public Cell get () {
            Cell cell = {row_index, col_index, data[row_index, col_index]};
            row_index++;
            if (row_index > row_limit) {
                row_index = 0;
                col_index++;
            }

            return cell;
        }
    }
}
