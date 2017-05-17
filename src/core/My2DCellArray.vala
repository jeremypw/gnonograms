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
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {
/*** NOTE:  This class does not range check coordinates passed as parameters - that is the responsibility
   *        of the calling function.
***/
public class My2DCellArray  : GLib.Object {
//~     private Model? model;

    public Dimensions dimensions;

    public uint rows {
        get {
            return dimensions.height;
        }
    }

    public uint cols {
        get {
            return dimensions.width;
        }
    }

    private CellState[,] data;

    construct {
        data = new CellState[MAXSIZE, MAXSIZE];
    }

//~     public My2DCellArray (Model? model, CellState init) {
//~         this.dimensions = model.dimensions;
//~         set_all (init);
//~     }

    public My2DCellArray (Dimensions dimensions, CellState init = CellState.EMPTY) {
        this.dimensions = dimensions;
        set_all (init);
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
            get_col(idx, ref sa, start);
        } else {
            get_row (idx, ref sa, start);
        }
    }

    public void set_array (uint idx, bool iscolumn, CellState[] sa, uint start = 0) {
        if (iscolumn) {
            set_col (idx, sa, start);
        } else {
            set_row(idx, sa, start);
        }
    }

    public void set_all (CellState s) {
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                data[r,c] = s;
            }
        }
    }

    public string data2text (uint idx, uint length, bool iscolumn) {
        CellState[] arr = new CellState[length];
        this.get_array (idx, iscolumn, ref arr);
        return Utils.block_string_from_cellstate_array (arr);
    }

//~     public Cell get_cell (uint r, uint c) {
//~         return {r, c, data[r,c]};
//~     }

    public void copy (My2DCellArray ca) {
        for (uint r = 0; r < uint.min (ca.rows, this.rows); r++) {
            for (uint c = 0; c < uint.min (ca.cols, this.cols); c++) {
                data[r,c] = ca.get_data_from_rc (r, c);
            }
        }
    }

    public Iterator iterator() {
        return new Iterator (data, dimensions);
    }

    public class Iterator {
        private uint row_limit {get; set;}
        private uint col_limit {get; set;}
        private CellState [ , ] data {get; set;}

        private uint row_index = 0;
        private uint col_index = 0;

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
