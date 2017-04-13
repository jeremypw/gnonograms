/* game_editor class for Gnonograms3
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

public class Game_Editor : Gtk.Dialog
{
    private class Clue_Entry : Gtk.Entry
    {
        public int index;
        public bool is_column;

        public Clue_Entry(int index, bool is_column)
        {
            this.index=index;
            this.is_column=is_column;
        }
    }


    Clue_Entry[] _row_clues;
    Clue_Entry[] _col_clues;
    Entry name_entry;
    Entry source_entry;
    Entry date_entry;
    Entry license_entry;
    int row_page;
    int col_page;
    int errors;

    public Game_Editor(int rows, int cols, string name="", string source="", string date="")
    {

        _row_clues=new Clue_Entry[rows];
        _col_clues=new Clue_Entry[cols];
        errors=0;

        this.set_default_size(-1,512);
        this.add_events(Gdk.EventMask.FOCUS_CHANGE_MASK);

        Notebook notebook=new Gtk.Notebook();
        Label l;
        Box h;
        Box v;
        ScrolledWindow win;


        //v=new VBox(false,2);
        v=new Box(Gtk.Orientation.VERTICAL,2); v.set_homogeneous(false);
        l=new Label(_("Name of puzzle"));
        l.set_size_request(125,-1);
        l.set_alignment((float)0.0,(float)0.5);
        name_entry = new Gtk.Entry();
        name_entry.set_max_length(32);
        name_entry.set_size_request(300,-1);
        //h = new HBox(false,3);
        h= new Box(Gtk.Orientation.HORIZONTAL,3); h.set_homogeneous(false);
        h.pack_start(l,false,true,3);
        h.pack_start(name_entry,false,true,3);
        v.pack_start(h,false,false,3);

        l=new Label(_("Source"));
        l.set_size_request(125,-1);
        l.set_alignment((float)0.0,(float)0.5);
        source_entry = new Gtk.Entry();
        source_entry.set_max_length(32);
        source_entry.set_size_request(300,-1);
        //h = new HBox(false,3);
        h= new Box(Gtk.Orientation.HORIZONTAL,3); h.set_homogeneous(false);
        h.pack_start(l,false,true,3);
        h.pack_start(source_entry,false,true,3);
        v.pack_start(h,false,false,3);

        l=new Label(_("Date"));
        l.set_size_request(125,-1);
        l.set_alignment((float)0.0,(float)0.5);
        date_entry = new Gtk.Entry();
        date_entry.set_max_length(16);
        date_entry.set_size_request(125,-1);
        //h = new HBox(false,3);
        h= new Box(Gtk.Orientation.HORIZONTAL,3); h.set_homogeneous(false);
        h.pack_start(l,false,true,3);
        h.pack_start(date_entry,false,true,3);
        v.pack_start(h,false,false,3);

        l=new Label(_("License"));
        l.set_size_request(125,-1);
        l.set_alignment((float)0.0,(float)0.5);
        license_entry = new Gtk.Entry();
        license_entry.set_max_length(50);
        license_entry.set_size_request(125,-1);
        //h = new HBox(false,3);
        h= new Box(Gtk.Orientation.HORIZONTAL,3); h.set_homogeneous(false);
        h.pack_start(l,false,true,3);
        h.pack_start(license_entry,false,true,3);
        v.pack_start(h,false,false,3);

        l=new Label(_("Description"));
        notebook.append_page(v,l);

        //v=new VBox(false,2);
        v=new Box(Gtk.Orientation.VERTICAL,2); v.set_homogeneous(false);
        for (int i=0; i<rows; i++)
        {
            _row_clues[i]=new Clue_Entry(i,false);
            _row_clues[i].set_size_request(300,-1);
            _row_clues[i].set_text("0");
            _row_clues[i].focus_out_event.connect(validate_clue);

            l= new Label(@"Row clue $(i+1)");
            l.set_size_request(125,-1);
            l.set_alignment((float)0.0,(float)0.5);
            //h = new HBox(false,3);
            h= new Box(Gtk.Orientation.HORIZONTAL,3); h.set_homogeneous(false);
            h.pack_start(l,false,true,3);
            h.pack_end(_row_clues[i],false,true,3);

            v.pack_start(h,false,false,3);
        }

        win = new ScrolledWindow(null, null);
        win.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        win.add_with_viewport(v);

        l =new Label(_("Row clues"));
        row_page=notebook.append_page(win,l);

        //v=new VBox(false,2);
        v=new Box(Gtk.Orientation.VERTICAL,2); v.set_homogeneous(false);
        for (int i=0; i<cols; i++)
        {
            _col_clues[i]=new Clue_Entry(i,true);
            _col_clues[i].set_size_request(300,-1);
            _col_clues[i].set_text("0");
            _col_clues[i].focus_out_event.connect(validate_clue);

            l= new Label(@"Column clue $(i+1)");
            l.set_size_request(125,-1);
            l.set_alignment((float)0.0,(float)0.5);
            //h = new HBox(false,3);
            h= new Box(Gtk.Orientation.HORIZONTAL,3); h.set_homogeneous(false);

            h.pack_start(l,false,true,3);
            h.pack_end(_col_clues[i],false,true,3);

            v.pack_start(h,false,false,3);
        }

        win = new ScrolledWindow(null, null);
        win.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        win.add_with_viewport(v);

        l=new Label(_("Column clues"));
        col_page=notebook.append_page(win,l);

        var vbox=(Gtk.Box)(this.get_content_area());
        vbox.pack_start(notebook,true,true,3);
        this.add_buttons(Gtk.Stock.OK, Gtk.ResponseType.OK, Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
//      this.add_buttons(Gtk.STOCK_OK, Gtk.ResponseType.OK, Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL);
    }

    public string get_rowclue(int index){return _row_clues[index].get_text();}
    public string get_colclue(int index){return _col_clues[index].get_text();}
    public void set_rowclue(int index, string clue){_row_clues[index].set_text(clue);}
    public void set_colclue(int index, string clue){_col_clues[index].set_text(clue);}
    public string get_name(){return name_entry.get_text();}
    public void set_name(string name){name_entry.set_text(name);}
    public string get_source(){return source_entry.get_text();}
    public void set_source(string source){source_entry.set_text(source);}
    public string get_date(){return date_entry.get_text();}
    public void set_date(string date){date_entry.set_text(date);}
    public string get_license(){return license_entry.get_text();}
    public void set_license(string license){license_entry.set_text(license);}

    public bool validate_clue(Gtk.Widget w, Gdk.EventFocus event)
    {
        string text;
        string copy;
        bool valid;
        Clue_Entry entry;

        entry=((Clue_Entry)w);
        text=entry.get_text();
        copy=text.dup();
        copy.canon("0123456789, ",',');

        valid=false;
        if (text==copy)
        {
            int block_extent=Utils.blockextent_from_clue(copy);
            int dimension= entry.is_column ? _row_clues.length : _col_clues.length;

            if (block_extent<=dimension)
            {
                valid=true;
                //cleanup format of clue by passing through block array
                entry.set_text(Utils.clue_from_block_array(Utils.block_array_from_clue(copy)));
            }
        }
        if (!valid)
        {
            if (w.get_state()==Gtk.StateType.NORMAL)
            {
                w.set_state(Gtk.StateType.SELECTED);
                this.errors++;
                this.set_response_sensitive(Gtk.ResponseType.OK,false);
            }
        }
        else
        {
            if(w.get_state()==Gtk.StateType.SELECTED)
            {
                this.errors--;
                w.set_state(Gtk.StateType.NORMAL);
                if (errors==0) this.set_response_sensitive(Gtk.ResponseType.OK,true);
            }
        }
        return false;
    }
}
