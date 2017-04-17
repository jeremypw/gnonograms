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
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */
namespace Gnonograms {

public class Model : GLib.Object {
    public Dimensions dimensions {get; set;}
    public My2DCellArray display_data  {get; private set;}  //points to grid being displayed
    private My2DCellArray solution_data; //display when setting
    private My2DCellArray working_data; //display when solving
    public  CellState[] data;
    private Rand rand_gen;

    private int rows {get {return dimensions.height;}}
    private int cols {get {return dimensions.width;}}

    construct {
        rand_gen = new Rand();
    }

    public Model(Dimensions dimensions) {
        Object (dimensions: dimensions);
        solution_data=new My2DCellArray(dimensions, CellState.EMPTY);
        working_data=new My2DCellArray(dimensions, CellState.UNKNOWN);
        data = new CellState[MAXSIZE];
        display_data = solution_data;
    }

    public void clear_errors()
    {
        CellState cs;
        for (int r=0;r<rows; r++)
        {
            for (int c=0;c<cols;c++)
            {
                cs=working_data.get_data_from_rc(r,c);
                if (cs==CellState.ERROR_EMPTY||cs==CellState.ERROR_FILLED)
                {
                    if (cs==CellState.ERROR_EMPTY)
                    {
                        working_data.set_data_from_rc(r,c,CellState.EMPTY);
                    }
                    else if (cs==CellState.ERROR_FILLED)
                    {
                        working_data.set_data_from_rc(r,c,CellState.FILLED);

                    }
                }
            }
        }
    }

    public int count_errors()
    {
        CellState cs;
        int count=0;
        for (int r=0;r<rows; r++)
        {
            for (int c=0;c<cols;c++)
            {
                cs=working_data.get_data_from_rc(r,c);
                if
                (
                    cs==CellState.ERROR_EMPTY ||
                    cs==CellState.ERROR_FILLED ||
                    (   cs!=CellState.UNKNOWN&&cs!=solution_data.get_cell(r,c).state)
                )
                {
                    if (cs==CellState.EMPTY)
                    {
                        working_data.set_data_from_rc(r,c,CellState.ERROR_EMPTY);
                    }
                    else if (cs==CellState.FILLED)
                    {
                        working_data.set_data_from_rc(r,c,CellState.ERROR_FILLED);

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
        for (int r=0;r<rows; r++)
        {
            for (int c=0;c<cols;c++)
            {
                cs=working_data.get_data_from_rc(r,c);
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
        solution_data.set_all(CellState.EMPTY);
    }

    public void blank_working(CellState blank=CellState.UNKNOWN)
    {
        working_data.set_all(CellState.UNKNOWN);
    }

    public void display_working()
    {
        display_data=working_data;
    }

    public void display_solution()
    {
        display_data=solution_data;
    }

    public string get_label_text(int idx,bool is_column,bool from_solution=true)
    {
        int length = is_column ? rows : cols;
        if (from_solution)
        {
            return solution_data.data2text(idx,length, is_column);
        }
        else
        {
            return working_data.data2text(idx,length, is_column);
        }
    }

    public Cell get_cell(int r, int c)
    {
        return display_data.get_cell(r,c);
    }

    public void set_data_from_cell(Cell cell)
    {
        display_data.set_data_from_cell(cell);
    }

    public CellState get_data_from_rc(int r, int c)
    {
        return display_data.get_data_from_rc(r,c);
    }

    public bool set_row_data_from_string(int r, string s)
    {
        CellState[] cs =Utils.cellstate_array_from_string(s);
        return set_row_data_from_data_array(r, cs);
    }

    public bool set_row_data_from_data_array(int r, CellState[] cs)
    {
        if (cs.length!=cols)
        {
            warning ("Wrong number of columns in data");
            return false;
        }
        display_data.set_row(r, cs);
        return true;
    }

    public string to_string()
    {
        //stdout.printf("model to string\n");
        StringBuilder sb= new StringBuilder();
        CellState[] arr=new CellState[cols];
        for (int r=0; r<rows; r++)
        {
            display_data.get_row(r, ref arr);
            sb.append(Utils.string_from_cellstate_array(arr));
            sb.append("\n");
        }
        return sb.str;
    }

    public string to_hexstring()
    {
        //stdout.printf("model to string\n");
        StringBuilder sb= new StringBuilder();
        CellState[] arr=new CellState[cols];
        for (int r=0; r<rows; r++)
        {
            display_data.get_row(r, ref arr);
            sb.append(Utils.hex_string_from_cellstate_array(arr));
            sb.append("\n");
        }
        return sb.str;
    }

    public void fill_random(int grade)
    {
        clear();
        int midcol = rows/2;
        int midrow =cols/2;
        int mincdf = 2+(int)((rows*grade)/(MAXGRADE*4));
        int minrdf = 2+(int)((cols*grade)/(MAXGRADE*4));

        for (int e=0; e<data.length; e++) data[e]=CellState.EMPTY;

        int maxb=1+(int)(cols*(1.0-grade/MAXGRADE));
        for (int r=0;r<rows;r++)
        {
            solution_data.get_row(r, ref data);
            fill_region(cols, ref data, grade, (r-midcol).abs(), maxb, cols);
            solution_data.set_row(r, data);
        }
        maxb=1+(int)(rows*(1.0-grade/MAXGRADE));
        for (int c=0;c<cols;c++)
        {
            solution_data.get_col(c, ref data);
            fill_region(rows, ref data, grade, (c-midrow).abs(), maxb, rows);
            solution_data.set_col(c, data);
        }

        for (int r=0;r<rows;r++)
        {
            solution_data.get_row(r, ref data);
            adjust_region(cols, ref data,minrdf);
            solution_data.set_row(r, data);
        }

        for (int c=0;c<cols;c++)
        {
            solution_data.get_col(c, ref data);
            adjust_region(rows, ref data,mincdf);
            solution_data.set_col(c, data);
        }
    }

    private void fill_region (int size, ref CellState[] data, int grade, int e, int maxb, int maxp)
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
            fill=rand_gen.int_range(0,maxp)>(baseline+(p-mid).abs());

            // random length up to remaining space but not larger than
            // maxb for filled cells or size-maxb for empty cells
            // bsize=int.min(rand_gen.int_range(0,size-p),maxb);
            bsize=int.min(rand_gen.int_range(0,size-p),fill ? maxb : size-maxb);

            for (int i=0; i<bsize; i++)
            {
                if (fill) data[p]=CellState.FILLED;
                p++;
            }
            p++; //at least one space between blocks

            if (fill && p<size) data[p]=CellState.EMPTY;
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
            arr[rand_gen.int_range(0,s)]=CellState.FILLED;
        }
        else // empty cells until reach min freedom
        {
            int count=0;
            while (df<mindf&&count<30)
            {
                count++;
                int i=rand_gen.int_range(1,s-1);
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
        int size = iscolumn ? rows : cols;
        int array_idx = iscolumn ? c : r;
        int ptr = iscolumn ? r : c;
        int count=0;
        CellState cs;
        var arr = new CellState[size];
        display_data.get_array(array_idx, iscolumn, ref arr);
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
}
