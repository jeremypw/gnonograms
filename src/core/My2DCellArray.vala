/* Two dimensional array of cell states allowing access and updating by row and column regions.
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

namespace Gnonograms {

public class My2DCellArray  : GLib.Object {
    public Gnonograms.Dimensions dimensions {get; set;}
    private int rows {
        get {
            return dimensions.height;    
        }
    }

    private int cols {
        get {
            return dimensions.width;
        }
    }

    private CellState[,] data;

    public My2DCellArray (Dimensions dimensions, CellState init) {
        Object (dimensions: dimensions);
        data = new CellState[rows, cols];
        set_all (init);
    }

    public void set_data_from_cell (Cell c) {
        data[c.row,c.col] = c.state;
    }

    public void set_data_from_rc (int r, int c, CellState s) {
        data[r,c] = s;
    }

    public CellState get_data_from_rc (int r, int c) {
        return data[r,c];
    }

    public Cell get_cell (int r, int c) {
        return {r, c, data[r,c]};
    }

    public void get_row (int row, ref CellState[] sa, int start = 0) {
        for (int c = start; c < start + sa.length; c++) {
            sa[c] = data[row,c];
        }
    }

    public void set_row (int row, CellState[] sa, int start = 0) {
        for (int c = 0; c < sa.length; c++) {
            data[row, c + start] = sa[c];
        }
    }

    public void get_col (int col, ref CellState[] sa, int start = 0) {
        for (int r = start; r < start + sa.length; r++) {
            sa[r] = data[r, col];
        }
    }

    public void set_col (int col, CellState[] sa, int start = 0) {
        for (int r = 0; r < sa.length; r++) {
            data[r + start, col] = sa[r];
        }
    }

    public void get_array (int idx, bool iscolumn, ref CellState[] sa, int start = 0) {
        if (iscolumn) {
            get_col(idx, ref sa, start);
        } else {
            get_row (idx, ref sa, start);
        }
    }

    public void set_array (int idx, bool iscolumn, CellState[] sa, int start = 0) {
        if (iscolumn) {
            set_col (idx, sa, start);
        } else {
            set_row(idx, sa, start);
        }
    }

    public void set_all (CellState s) {
        for (int r = 0; r < rows; r++) {
            for (int c = 0;c < cols; c++) {
                data[r,c] = s;
            }
        }
    }

    public string data2text (int idx, int length, bool iscolumn) {
        CellState[] arr = new CellState[length];
        this.get_array (idx, iscolumn, ref arr);
        return Utils.block_string_from_cellstate_array (arr);
    }

    public void copy (My2DCellArray ca) {
        for (int r = 0; r < int.min (ca.rows, this.rows); r++) {
            for (int c = 0; c < int.min (ca.cols, this.cols); c++) {
                data[r,c] = ca.get_data_from_rc (r, c);
            }
        }
    }

    public Iterator iterator() {
        return new Iterator (data, dimensions);
    }

    public class Iterator {
        private int row_limit {get; set;}
        private int col_limit {get; set;}
        private CellState [ , ] data {get; set;}

        private int row_index = 0;
        private int col_index = 0;

        public Iterator (CellState [,] data, Dimensions dimensions) {
            this.data = data;
            row_limit = dimensions.height - 1;
            col_limit = dimensions.width - 1;
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
}
