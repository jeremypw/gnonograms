/* 2D array of Cells class for Gnonograms3
 * Represents the state of a cell grid
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
 * 	Jeremy Wootten <jeremwootten@gmail.com>
 */

 public class My2DCellArray
{
	private int _rows;
	private int _cols;
	private CellState[,] _data;

	public My2DCellArray(int rows, int cols, CellState init=CellState.UNKNOWN)
	{
		_rows=rows; _cols=cols;
		_data = new CellState[_rows,_cols];
		set_all(init);
	}

	public int rows() {return _rows;}

	public int cols() {return _cols;}

	public void set_data_from_cell(Cell c) {_data[c.row,c.col]=c.state;}

	public void set_data_from_rc(int r, int c, CellState s) {_data[r,c]=s;}

	public CellState get_data_from_rc(int r, int c) {return _data[r,c];}

	public Cell get_cell(int r, int c) {return {r,c,_data[r,c]};}

	public void get_row(int row, ref CellState[] sa, int start=0)
	{
		for (int c=start;c<start+sa.length;c++) sa[c]=_data[row,c];
	}

	public void set_row(int row, CellState[] sa, int start=0)
	{
		for (int c=0;c<sa.length;c++) _data[row,c+start]=sa[c];
	}

	public void get_col(int col, ref CellState[] sa, int start=0)
	{
		for (int r=start;r<start+sa.length;r++) {sa[r]=_data[r,col];}
	}

	public void set_col(int col, CellState[] sa, int start=0)
	{
		for (int r=0;r<sa.length;r++) {_data[r+start,col]=sa[r];}
	}

	public void get_array(int idx, bool iscolumn, ref CellState[] sa, int start=0)
	{
		if (iscolumn) get_col(idx, ref sa, start);
		else get_row(idx, ref sa, start);
	}

	public void set_array(int idx, bool iscolumn, CellState[] sa, int start=0)
	{
		if (iscolumn) set_col(idx, sa, start);
		else set_row(idx, sa, start);
	}

	public void set_all(CellState s)
	{
		for (int r=0; r<_rows; r++)
		{
			for (int c=0;c<_cols;c++)
			{
				_data[r,c]=s;
			}
		}
	}

	public string data2text(int idx, int length, bool iscolumn)
	{
		CellState[] arr = new CellState[length];
		this.get_array(idx, iscolumn, ref arr);
		return Utils.block_string_from_cellstate_array(arr);
	}

	public void copy(My2DCellArray ca)
	{
		int rows = int.min(ca.rows(), this.rows());
		int cols	= int.min(ca.cols(), this.cols());

		for (int r=0; r<rows; r++)
		{	for (int c=0; c<cols; c++)
			{
				_data[r,c]=ca.get_data_from_rc(r,c);
			}
		}
	}
}
