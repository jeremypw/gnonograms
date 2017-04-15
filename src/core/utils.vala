/* Utility functions for Gnonograms3
 * Dialogs, conversions etc
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
 using Gtk;
 using GLib;

namespace Gnonograms.Utils
{
    public static string[] remove_blank_lines(string[] sa)
    {
        string[] result = {};
        for (int i=0; i<sa.length; i++)
        {
            if (sa[i]==null) continue;
            string s=sa[i].strip();
            if (s=="") continue;
            result+=s;
        }
        return result;
    }

    public int[] block_array_from_clue(string s)
    {
        string[] clues=remove_blank_lines(s.split_set(", "));

        if(clues.length==0) clues={"0"};
        int[] blocks=new int[clues.length];

        for (int i=0;i<clues.length;i++) blocks[i]=int.parse(clues[i]);

        return blocks;
    }

    public int blockextent_from_clue(string s)
    {
        int[] blocks = block_array_from_clue(s);
        int extent=0;
        foreach(int block in blocks) extent+=(block+1);
        extent--;
        return extent;
    }
}
