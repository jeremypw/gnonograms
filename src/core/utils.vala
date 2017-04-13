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

namespace Utils
{
    public static string get_stripped_basename(string path, string? ext)
    {
            string bn=Path.get_basename(path);
            if ((ext!=null) && bn.has_suffix(ext))
                bn=bn[0:-ext.length];
            return bn;
    }
    public static string get_directory(string path)
    {
            string bn=Path.get_basename(path);
            return path[0:-bn.length];
    }



    public static string get_string_response(string prompt)
    {
        var dialog = new Gtk.Dialog.with_buttons (
            null,
            null,
            Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
            _("Ok"), Gtk.ResponseType.OK,
            _("Cancel"), Gtk.ResponseType.CANCEL);
        Gtk.Entry entry=new Gtk.Entry();
        dialog.get_content_area().add(new Gtk.Label(prompt));
        dialog.get_content_area().add(entry);
        dialog.show_all();
        dialog.run();
        string fn=entry.text;
        dialog.destroy();
        return fn;
    }

    public static string get_file_path(FileChooserAction action, string dialogname, string[]? filternames, string[]? filters, string? start_path=null)
    {
        if (filternames!=null) assert(filternames.length==filters.length);
        string button="Error";
        switch (action)
        {
            case FileChooserAction.OPEN:
                button=Gtk.Stock.OPEN;
                break;

            case FileChooserAction.SAVE:
                button=Gtk.Stock.SAVE;
                break;
            case FileChooserAction.SELECT_FOLDER:
                button=Gtk.Stock.APPLY;
                break;
            default :
                break;
        }

        var dialog=new Gtk.FileChooserDialog(
            dialogname,
            null,
            action,
            Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
            button, Gtk.ResponseType.ACCEPT,
            null);

        if (filternames!=null)
        {
            for (int i=0; i<filternames.length; i++)
            {
                var fc=new Gtk.FileFilter();
                fc.set_filter_name(filternames[i]);
                fc.add_pattern(filters[i]);
                dialog.add_filter(fc);
            }
        }

        if (start_path!=null)
        {
            var start=File.new_for_path(start_path);
            if (start.query_file_type(FileQueryInfoFlags.NONE,null)==FileType.DIRECTORY)
            {
                Environment.set_current_dir(start_path);
                dialog.set_current_folder(start_path); //so Recently used folder not displayed
            }
        }
        //only need access to built-in puzzle directory if loading a .gno puzzle
        if (action==FileChooserAction.OPEN && filters!=null && filters[0]=="*.gno")
        {
             dialog.add_button(_("Built in puzzles"),Gtk.ResponseType.NONE);
        }

        int response;
        while(true)
        {
            response = dialog.run();
            if(response==Gtk.ResponseType.NONE)
            {
                dialog.set_current_folder(Resource.resource_dir+"/games");
            }
            else break;
        }

        string fn="";
        if (response==ResponseType.ACCEPT){
            fn=dialog.get_filename();
            Environment.set_current_dir(dialog.get_current_folder());
        }
        dialog.destroy();

        return fn;
    }

    public bool get_dimensions(out int r, out int c, int currentr=5, int currentc=5)
    {
        r=currentr; c=currentc;
        if(r<5)r=5;
        if(c<5)c=5;

        Gtk.Dialog dialog=new Gtk.Dialog.with_buttons(_("Adjust Size"),
            null,
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
            Gtk.Stock.OK,
            Gtk.ResponseType.OK,
            Gtk.Stock.CANCEL,
            Gtk.ResponseType.CANCEL
            );
        Gtk.Box hbox=new Gtk.Box(Gtk.Orientation.HORIZONTAL,6); hbox.set_homogeneous(true);
        Gtk.Label row_label=new Gtk.Label(_("Rows"));
        Gtk.SpinButton row_spin=new Gtk.SpinButton.with_range(1.0,Resource.MAXSIZE,5.0);
        row_spin.set_value((double)currentr);

        Gtk.Label col_label=new Gtk.Label(_("Columns"));
        Gtk.SpinButton col_spin=new Gtk.SpinButton.with_range(Resource.MINSIZE,Resource.MAXSIZE,5.0);
        col_spin.set_value((double)currentc);

        hbox.add(row_label); hbox.add(row_spin);
        hbox.add(col_label); hbox.add(col_spin);

        Gtk.Box vbox=dialog.get_content_area();
        vbox.add(hbox);
        dialog.set_default_response(Gtk.ResponseType.OK);
        dialog.show_all();

        bool success=false;
        int response=dialog.run();

        if (response==(int)Gtk.ResponseType.OK) {
            r=int.max(1,row_spin.get_value_as_int());
            c=int.max(1,col_spin.get_value_as_int());
            success=true;
        }
        dialog.destroy();
        return success;
    }

    public static  int show_dlg(string msg, Gtk.MessageType type, Gtk.ButtonsType buttons)
    {
        //stdout.printf("Show dlg\n");
        var dialog=new Gtk.MessageDialog(
            null,
            Gtk.DialogFlags.MODAL,
            type,
            buttons,
            "%s",msg);
        dialog.set_position(Gtk.WindowPosition.MOUSE);
        int response=dialog.run();
        dialog.destroy();
        return response;

    }

    public static void show_info_dialog(string msg)
    {
        show_dlg(msg,Gtk.MessageType.INFO,Gtk.ButtonsType.CLOSE);
    }

    public static void show_warning_dialog(string msg)
    {
        show_dlg(msg,Gtk.MessageType.WARNING,Gtk.ButtonsType.CLOSE);
    }

    public static void show_error_dialog(string msg)
    {
        show_dlg(msg,Gtk.MessageType.ERROR,Gtk.ButtonsType.CLOSE);
    }

    public static bool show_confirm_dialog(string msg)
    {
        return show_dlg(msg,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO)==Gtk.ResponseType.YES;
    }

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

    public DataInputStream? open_datainputstream(string filename)
    {
        //stdout.printf(@"opening $filename\n");
        DataInputStream stream;
        var file = File.new_for_path (filename);
        if (!file.query_exists (null))
        {
           stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
           return null;
        }

        try
        {
            stream= new DataInputStream(file.read(null));
        }
        catch (Error e) {Utils.show_warning_dialog(e.message); return null;}
        return stream;
    }

    public CellState[] cellstate_array_from_string(string s)
    {
        CellState[] cs ={};
        string[] data=remove_blank_lines(s.split_set(", "));
        for (int i=0; i<data.length; i++) cs+=(CellState)(int.parse(data[i]).clamp(0,6));
        return cs;
    }

    public string gnonogram_string_from_hex_string(string s, int pad_to_length)
    {
        StringBuilder sb= new StringBuilder(""); int count=0;
        for (int i=0; i<s.length; i++)
        {
            switch (s[i].toupper())
            {
                case '0':
                    sb.append("1,1,1,1,");count+=4;break;
                case '1':
                    sb.append("1,1,1,2,");count+=4;break;;
                case '2':
                    sb.append("1,1,2,1,");count+=4;break;;
                case '3':
                    sb.append("1,1,2,2,");count+=4;break;;
                case '4':
                    sb.append("1,2,1,1,");count+=4;break;;
                case '5':
                    sb.append("1,2,1,2,");count+=4;break;;
                case '6':
                    sb.append("1,2,2,1,");count+=4;break;;
                case '7':
                    sb.append("1,2,2,2,");count+=4;break;;
                case '8':
                    sb.append("2,1,1,1,");count+=4;break;;
                case '9':
                    sb.append("2,1,1,2,");count+=4;break;;
                case 'A':
                    sb.append("2,1,2,1,");count+=4;break;;
                case 'B':
                    sb.append("2,1,2,2,");count+=4;break;;
                case 'C':
                    sb.append("2,2,1,1,");count+=4;break;;
                case 'D':
                    sb.append("2,2,1,2,");count+=4;break;;
                case 'E':
                    sb.append("2,2,2,1,");count+=4;break;;
                case 'F':
                    sb.append("2,2,2,2,");count+=4;break;;
            }
        }

        if (pad_to_length>0)
        {
            if (count<pad_to_length)
            {
                for (int i=count; i<pad_to_length; i++)
                {
                    sb.prepend("1,");
                }
            }
            else if (count>pad_to_length)
            {
                sb.erase(0,(count-pad_to_length)*2);
            }
        }

        return sb.str;
    }

    public string hex_string_from_cellstate_array(CellState[] sa)
    {
        StringBuilder sb= new StringBuilder("");
        int length=sa.length;
        int e=0, m=1, count=0;
        for(int i=length-1;i>=0;i--)
        {
            count++;
            e+=((int)(sa[i])-1)*m;
            m=m*2;
            if(count==4||i==0)
            {
                sb.prepend(int2hex(e));
                count=0;m=1;e=0;
            }
        }
        return sb.str;
    }

    private string int2hex(int i)
    {
        if (i<=9) return i.to_string();
        if (i>15) return "X";
        i=i-10;
        string[] l={"A","B","C","D","E","F"};
        return l[i];
    }

    public string convert_html(string? html)
    {
        if (html==null) return "";

        try
        {
            var regex = new GLib.Regex("&#([0-9]+);");
            string[] s = regex.split(html);

            if (s.length>1) //html entity found - convert to unicode
            {
                var sb=new StringBuilder("");
                for (int i=0; i<s.length;i++)
                {   int u=int.parse(s[i]);
                    if (u>31 && u<65535)
                    {
                        sb.append_unichar((unichar)u);
                    }
                    else if (s[i]!="") sb.append(s[i]);
                }
                return sb.str;
            }
            return html;
        }
        catch (RegexError re) {show_warning_dialog(re.message); return "";}

    }

    public string string_from_cellstate_array(CellState[] cs)
    {
        //stdout.printf("string from cell_state_array\n");
        if (cs==null) return "";
        StringBuilder sb= new StringBuilder();
        for (int i=0; i<cs.length; i++)
        {
            sb.append(((int)cs[i]).to_string());
            sb.append(" ");
        }
        return sb.str;
    }

    public string block_string_from_cellstate_array(CellState[] cs)
    {
        //stdout.printf("block string from cell_state_array length %d\n", cs.length);
        StringBuilder sb= new StringBuilder("");
        int count=0, blocks=0;
        bool counting=false;

        for (int i=0; i<cs.length; i++)
        {
            if (cs[i]==CellState.EMPTY)
            {
                if (counting)
                {
                    sb.append(count.to_string()+Resource.BLOCKSEPARATOR);
                    counting=false;
                    count=0;
                    blocks++;
                }
            }
            else if(cs[i]==CellState.FILLED)
            {
                counting=true;
                count++;
            }
            else
            {
                stdout.printf("Error in block string from cellstate array - Cellstate UNKNOWN OR IN ERROR\n");
                break;
            }
        }
        if (counting)
        {
            sb.append(count.to_string()+Resource.BLOCKSEPARATOR);
            blocks++;
        }
        if (blocks==0) sb.append("0");
        else sb.truncate(sb.len -1);

        return sb.str;
    }

    public int[] block_array_from_clue(string s)
    {
        //stdout.printf(@"Block array from clue $s \n");
        string[] clues=remove_blank_lines(s.split_set(", "));

        if(clues.length==0) clues={"0"};
        int[] blocks=new int[clues.length];

        for (int i=0;i<clues.length;i++) blocks[i]=int.parse(clues[i]);

        return blocks;
    }

    public string clue_from_block_array(int[] b)
    {
        StringBuilder sb=new StringBuilder("");
        foreach(int block in b)
        {
            sb.append(block.to_string());
            sb.append(Resource.BLOCKSEPARATOR);
        }
        sb.truncate(sb.len -1);
        return sb.str;
    }

    public int blockextent_from_clue(string s)
    {
        int[] blocks = block_array_from_clue(s);
        int extent=0;
        foreach(int block in blocks) extent+=(block+1);
        extent--;
        return extent;
    }

    public string get_todays_date_string(){
        TimeVal t={};
        t.get_current_time();
        return (t.to_iso8601()).slice(0,10);
    }

    public void process_events()
    {
        while (Gtk.events_pending())
        {
            Gtk.main_iteration_do(false);
        }
    }
}
