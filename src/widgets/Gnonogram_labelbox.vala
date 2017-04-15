/* Label box class for Gnonograms3
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
public class LabelBox : Gtk.Frame
{
    private bool _is_column; //true if contains column labels(i.e. HBox)
    private int _size; //no of labels in box
    private int _other_size; //possible length of label text (size of other box)
    private Gnonograms.Label[] _labels;
    private Gtk.Box _box;
    private string _attribstart;
    private string _attribend;
    private double _fontheight;

    public LabelBox(int size, int other_size, bool is_col)
    {
        _is_column=is_col;
        this.set_shadow_type(Gtk.ShadowType.NONE);
        Gtk.Orientation o;
        if (_is_column)
        {
             o=Gtk.Orientation.HORIZONTAL;
        }
        else
        {
            o=Gtk.Orientation.VERTICAL;
        }

        _box = new Gtk.Box(o,0); //as Container;
        _box.set_homogeneous(true);
        _labels=new Gnonograms.Label[MAXSIZE];

        for (var i=0;i<_labels.length;i++)
        {
            var l=new Gnonograms.Label("", is_col);
            _labels[i]=l;
        }
        _size=0; //ensures 'size' no labels are added to box
        resize(size, other_size);
        add(_box);
    }

    public void resize(int new_size, int other_size)
    {
        //stdout.printf("Resize label box %s\n", new_size.to_string());
        unhighlight_all();
        if (new_size!=_size)
        {
            int diff=(new_size-_size);
            if (diff>0)
            {
                for (int i=0; i<diff; i++)
                {
                _box.add(_labels[_size]);
                _size++;
                }
            }
            else
            {
            GLib.List<weak Gtk.Widget> l=_box.get_children();
            uint length=l.length();
                for (int i=-1; i>=diff; i--)
                {
                    //stdout.printf("remove label\n");
                    _box.remove(l.nth_data(length+(uint)i));
                    _size--;
                }
            }
            if (_size!=new_size) stdout.printf("Error adding or removing labels");
            this.show_all();
        }
        _other_size=other_size;
    }

    public void change_font_height(bool increase)
    {
        if (increase) _fontheight+=1.0;
        else _fontheight-=1.0;
        set_font_height(_fontheight);
    }

    public void set_font_height(double fontheight)
    {
        _fontheight=fontheight.clamp(Gnonograms.MINFONTSIZE, Gnonograms.MAXFONTSIZE);
        set_attribs(_fontheight);
        for (int i=0; i<_size;i++) update_label(i,get_label_text(i));
    }

    public void highlight(int idx, bool is_highlight)
    {
        //stdout.printf(@"highlight $idx $is_highlight \n");
        if (idx>=_size||idx<0) return;
        _labels[idx].highlight(is_highlight);
    }

    private void unhighlight_all()
    {
        //stdout.printf("Unhighlight all\n");
        for (int i=0;i<_size;i++) {highlight(i,false);}
    }

    public void update_label(int idx, string? txt)
    {
        //stdout.printf("Idx %d Label txt %s\n",idx,txt);
        if (txt==null) txt="?";
        _labels[idx].set_markup(_attribstart,txt,_attribend);
        _labels[idx].set_size(_other_size, _fontheight);
    }

    public string get_label_text(int idx)
    {
        return _labels[idx].get_text();
    }

    public string to_string()
    {
        StringBuilder sb=new StringBuilder();

        for (int i=0; i<_size;i++)
        {
            sb.append(get_label_text(i));
            sb.append("\n");
        }

        return sb.str;
    }

    private void set_attribs(double fontheight)
    {
         int fontsize=1024*(int)(fontheight);
//~         _attribstart=@"<span font_desc='$(Resource.font_desc)' size='$fontsize'>";
        _attribstart=@"<span size='$fontsize'>";
        _attribend="</span>";
    }

    public void set_all_to_zero()
    {
        for(int l=0;l<_size;l++) update_label(l,"0");
    }
}
}
