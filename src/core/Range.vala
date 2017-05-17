/* Range class for gnonograms_elementary
 *
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

public class Range {  //can use for filled subregions or ranges of filled and unknown cells
    public int start;
    public int end;
    public int filled;
    public int unknown;

    public Range (int start, int end, int filled, int unknown) {
      this.start = start; //first cell in range
      this.end = end; // last cell in range
      this.filled = filled;
      this.unknown = unknown;
    }

    public int length () {
        return end - start + 1;
    }
}
}
