/* Model class for Gnonograms3
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
 public class Gnonogram_model
 {
	private int _rows;
	private int _cols;
	private My2DCellArray _display_data;  //points to grid being displayed
	private My2DCellArray _solution_data; //display when setting
	private My2DCellArray _working_data; //display when solving
	public CellState[] _arr;
	private Rand _rand_gen;

	public Gnonogram_model()
	{
		_rows = 10; _cols = 10; //Must call set dimensions before use
		_solution_data=new My2DCellArray(Resource.MAXSIZE,Resource.MAXSIZE,CellState.EMPTY);
		_working_data=new My2DCellArray(Resource.MAXSIZE,Resource.MAXSIZE,CellState.UNKNOWN);
		_arr = new CellState[Resource.MAXSIZE];
		_display_data = _solution_data;
		_rand_gen = new Rand();
	}

	public void clear_errors()
	{
		CellState cs;
		for (int r=0;r<_rows; r++)
		{
			for (int c=0;c<_cols;c++)
			{
				cs=_working_data.get_data_from_rc(r,c);
				if (cs==CellState.ERROR_EMPTY||cs==CellState.ERROR_FILLED)
				{
					if (cs==CellState.ERROR_EMPTY)
					{
						_working_data.set_data_from_rc(r,c,CellState.EMPTY);
					}
					else if (cs==CellState.ERROR_FILLED)
					{
						_working_data.set_data_from_rc(r,c,CellState.FILLED);

					}
				}
			}
		}
	}

	public int count_errors()
	{
		CellState cs;
		int count=0;
		for (int r=0;r<_rows; r++)
		{
			for (int c=0;c<_cols;c++)
			{
				cs=_working_data.get_data_from_rc(r,c);
				if
				(
					cs==CellState.ERROR_EMPTY ||
					cs==CellState.ERROR_FILLED ||
					(	cs!=CellState.UNKNOWN&&cs!=_solution_data.get_cell(r,c).state)
				)
				{
					if (cs==CellState.EMPTY)
					{
						_working_data.set_data_from_rc(r,c,CellState.ERROR_EMPTY);
					}
					else if (cs==CellState.FILLED)
					{
						_working_data.set_data_from_rc(r,c,CellState.ERROR_FILLED);

					}
					count++;
				}
			}
		}
		return count;
	}

	public int count_unsolved()
	{
		int count=0;
		CellState cs;
		for (int r=0;r<_rows; r++)
		{
			for (int c=0;c<_cols;c++)
			{
				cs=_working_data.get_data_from_rc(r,c);
				if (cs==CellState.UNKNOWN || cs==CellState.ERROR)count++;
			}
		}
		return count;
	}

	public void clear()
	{
		blank_solution();
		blank_working();
	}

	public void blank_solution(CellState blank=CellState.EMPTY)
	{
		_solution_data.set_all(CellState.EMPTY);
	}

	public void blank_working(CellState blank=CellState.UNKNOWN)
	{
		_working_data.set_all(CellState.UNKNOWN);
	}

	public void set_dimensions(int r, int c)
	{
		_rows=r;
		_cols=c;
	}

	public void use_working()
	{
		_display_data=_working_data;
	}

	public void use_solution()
	{
		_display_data=_solution_data;
	}

	public string get_label_text(int idx,bool is_column,bool from_solution=true)
	{
		int length = is_column ? _rows : _cols;
		if (from_solution)
		{
			return _solution_data.data2text(idx,length, is_column);
		}
		else
		{
			return _working_data.data2text(idx,length, is_column);
		}
	}

	public Cell get_cell(int r, int c)
	{
		return _display_data.get_cell(r,c);
	}

	public void set_data_from_cell(Cell cell)
	{
		_display_data.set_data_from_cell(cell);
	}

	public CellState get_data_from_rc(int r, int c)
	{
		return _display_data.get_data_from_rc(r,c);
	}

	public bool set_row_data_from_string(int r, string s)
	{
		CellState[] cs =Utils.cellstate_array_from_string(s);
		return set_row_data_from_array(r, cs);
	}

	public bool set_row_data_from_array(int r, CellState[] cs)
	{
		if (cs.length!=_cols)
		{
			Utils.show_warning_dialog(_("Error - wrong number of columns"));
			return false;
		}
		_display_data.set_row(r, cs);
		return true;
	}

	public string to_string()
	{
		//stdout.printf("model to string\n");
		StringBuilder sb= new StringBuilder();
		CellState[] arr=new CellState[_cols];
		for (int r=0; r<_rows; r++)
		{
			_display_data.get_row(r, ref arr);
			sb.append(Utils.string_from_cellstate_array(arr));
			sb.append("\n");
		}
		return sb.str;
	}

	public string to_hexstring()
	{
		//stdout.printf("model to string\n");
		StringBuilder sb= new StringBuilder();
		CellState[] arr=new CellState[_cols];
		for (int r=0; r<_rows; r++)
		{
			_display_data.get_row(r, ref arr);
			sb.append(Utils.hex_string_from_cellstate_array(arr));
			sb.append("\n");
		}
		return sb.str;
	}

	public void fill_random(int grade)
	{
		clear();
		int midcol = _rows/2;
		int midrow =_cols/2;
		int mincdf = 2+(int)((_rows*grade)/(Resource.MAXGRADE*4));
		int minrdf = 2+(int)((_cols*grade)/(Resource.MAXGRADE*4));

		for (int e=0; e<_arr.length; e++) _arr[e]=CellState.EMPTY;

		int maxb=1+(int)(_cols*(1.0-grade/Resource.MAXGRADE));
		for (int r=0;r<_rows;r++)
		{
			_solution_data.get_row(r, ref _arr);
			fill_region(_cols, ref _arr, grade, (r-midcol).abs(), maxb, _cols);
			_solution_data.set_row(r, _arr);
		}
		maxb=1+(int)(_rows*(1.0-grade/Resource.MAXGRADE));
		for (int c=0;c<_cols;c++)
		{
			_solution_data.get_col(c, ref _arr);
			fill_region(_rows, ref _arr, grade, (c-midrow).abs(), maxb, _rows);
			_solution_data.set_col(c, _arr);
		}

		for (int r=0;r<_rows;r++)
		{
			_solution_data.get_row(r, ref _arr);
			adjust_region(_cols, ref _arr,minrdf);
			_solution_data.set_row(r, _arr);
		}

		for (int c=0;c<_cols;c++)
		{
			_solution_data.get_col(c, ref _arr);
			adjust_region(_rows, ref _arr,mincdf);
			_solution_data.set_col(c, _arr);
		}
	}

	private void fill_region (int size, ref CellState[] _arr, int grade, int e, int maxb, int maxp)
	{
		//e is larger for rows/cols further from edge
		//do not want too many edge cells filled
		//maxb is maximum size of one random block
		//maxp is range of random number generator

		if (maxb<2) maxb=2;

		int p=0; //pointer
		int mid=size/2;
		int bsize; // blocksize
		int baseline = e+grade-10;
		// baseline relates to the probability of a filled block before
		// adjusting for distance from edge of region.
		bool fill;

		while (p<size)
		{
			// random choice whether to be full or empty, weighted so
			// less likely to fill squares close to edge
			fill=_rand_gen.int_range(0,maxp)>(baseline+(p-mid).abs());

			// random length up to remaining space but not larger than
			// maxb for filled cells or size-maxb for empty cells
			// bsize=int.min(_rand_gen.int_range(0,size-p),maxb);
			bsize=int.min(_rand_gen.int_range(0,size-p),fill ? maxb : size-maxb);

			for (int i=0; i<bsize; i++)
			{
				if (fill) _arr[p]=CellState.FILLED;
				p++;
			}
			p++; //at least one space between blocks

			if (fill && p<size) _arr[p]=CellState.EMPTY;
		}
	}

	private void adjust_region(int s, ref CellState [] arr, int mindf)
	{
		//s is size of region
		// mindf = minimum degrees of freedom
		if (s<5) return;
		int b=0; // count of filled cells
		int bc=0; // count of filled blocks
		int df=0; // degrees of freedom
		for (int i=0; i<s; i++)
		{
			if (arr[i]==CellState.FILLED)
			{
				b++;
				if (i==0 || arr[i-1]==CellState.EMPTY) bc++;
			}
		}
		df=s-b-bc+1;

		if (df>s) //completely empty - fill one cell
		{
			arr[_rand_gen.int_range(0,s)]=CellState.FILLED;
		}
		else // empty cells until reach min freedom
		{
			int count=0;
			while (df<mindf&&count<30)
			{
				count++;
				int i=_rand_gen.int_range(1,s-1);
				if (arr[i]==CellState.FILLED)
				{
					arr[i]=CellState.EMPTY;
					df++;
				}
			}
		}
	}

	public int get_runlength_at_rc(int r, int c, bool iscolumn)
	{
		int size = iscolumn ? _rows : _cols;
		int array_idx = iscolumn ? c : r;
		int ptr = iscolumn ? r : c;
		int count=0;
		CellState cs;
		var arr = new CellState[size];
		_display_data.get_array(array_idx, iscolumn, ref arr);
		cs=arr[ptr];
		while (ptr>0 && arr[ptr]==cs)
		{
			ptr--;
		}
		if (arr[ptr]!=cs)
		{
			ptr++;
		}
		while (ptr<size && arr[ptr]==cs)
		{
			count++;
			ptr++;
		}
		return count;
	}
}
