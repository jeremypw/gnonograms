/* Controller class for Gnonograms3
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


public class Circular_move_buffer
{

	private Move[] _buffer;
	int _start;
	int _end;
	int _pointer;
	int _size;
	int _nbr_items;
	int _offset;

	public Circular_move_buffer(int size)
	{
		_size=size;
		_buffer=new Move[_size];
		initialise_pointers();
	}

	public void initialise_pointers()
	{
		_start=0;_end=0;_pointer=0; _nbr_items=0; _offset=0;
	}

	public void new_data(Move data)
	{
		_buffer[_pointer]=data;
		_nbr_items+=1; _pointer+=1;
		if (_pointer==_size)_pointer=0;
		if (_offset==0) //no undos done
		{
			if (_nbr_items>_size) //buffer full -rotate end pointer
			{
				_start+=1; _nbr_items=_size;
				if (_start==_size) _start=0;
			}
		}
		else
		{
			_nbr_items-=_offset;
			_offset=0;
		}
	}

	public Move? previous_data()
	{
		if (_offset==_nbr_items) return null; //used all undos
		_pointer-=1;
		if (_pointer<0) _pointer=_size-1;
		_offset+=1;

		return _buffer[_pointer];
	}
	public Move? next_data()
	{
		if (_offset==0) return null;
		Move data = _buffer[_pointer];
		_pointer+=1;
		if (_pointer==_size) _pointer=0;
		_offset-=1;

		return data;
	}

	public bool no_more_previous_data()
	{
		return _offset==_nbr_items;
	}

	public bool no_more_next_data()
	{
		return _offset==0;
	}
}
