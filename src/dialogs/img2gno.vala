/* Img2gno class
 * Main UI window
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

//======================================================================
using Gtk;
using Gdk;

class Img2gno : Gtk.Dialog
{
    Gtk.Image _img;
    Gtk.ScrolledWindow _scrwin;
    Gdk.Pixbuf _pbo; //original image
    Gdk.Pixbuf _pbm; //unscaled mono image
    Gdk.Pixbuf _pbs; // final mono image
    Gtk.Scale _zoom;
    Gtk.Scale _thr_red_scale;
    Gtk.Scale _thr_green_scale;
    Gtk.Scale _thr_blue_scale;
    Gtk.Scale _thr_alpha_scale;

    Gtk.CheckButton _invertcheckbutton;
    Gtk.CheckButton _monocheckbutton;

    Gtk.Widget _okbutton;

    Gtk.Label _ht_label;
    Gtk.Label _wd_label;
    Gtk.Label _bts_label;
    Gtk.Label _channels_label;

    private string _name="";

    public Img2gno()
    {
        //var hb=new Gtk.HBox(false,2);
        var hb=new Gtk.Box(Gtk.Orientation.HORIZONTAL,2); hb.set_homogeneous(false);
        //var vb=new Gtk.VBox(false,2);
        var vb=new Gtk.Box(Gtk.Orientation.VERTICAL,2); vb.set_homogeneous(false);
        _img=new Gtk.Image();
        _scrwin=new Gtk.ScrolledWindow(null, null);
        _scrwin.set_policy(Gtk.PolicyType.AUTOMATIC,Gtk.PolicyType.AUTOMATIC);
        _scrwin.width_request=330;
        _scrwin.height_request=330;
        _scrwin.add_with_viewport(_img);
        hb.pack_end(_scrwin, true, true, 0);

        var load_button=new Gtk.Button.with_label(_("Load Image"));
        vb.pack_start(load_button,false, true, 0);

        //var h1=new Gtk.HBox(false,2);
        var h1=new Gtk.Box(Gtk.Orientation.HORIZONTAL,2); h1.set_homogeneous(false);
        _monocheckbutton=new Gtk.CheckButton.with_label(_("Monochrome"));
        _monocheckbutton.active=false;
        _monocheckbutton.sensitive=false;
        h1.pack_start(_monocheckbutton,false, true, 0);

        _invertcheckbutton=new Gtk.CheckButton.with_label(_("Invert image"));
        _invertcheckbutton.active=false;
        _invertcheckbutton.sensitive=false;
        h1.pack_start(_invertcheckbutton,false, true, 0);
        vb.pack_start(h1,true,true,2);

        _zoom=new Scale.with_range(Gtk.Orientation.HORIZONTAL,0.00,100.0,1.0);
        //_zoom.set_update_policy(Gtk.UpdateType.CONTINUOUS);
        _zoom.width_request=200;
        _zoom.sensitive=false;
        var f=new Gtk.Frame(_("Zoom %"));
        f.add(_zoom);
        vb.pack_start(f,false, true, 0);

        _thr_red_scale=new Scale.with_range(Gtk.Orientation.HORIZONTAL,0.00,1.00,0.01);
        //_thr_red_scale.set_update_policy(Gtk.UpdateType.DISCONTINUOUS);
        _thr_red_scale.width_request=200;
        _thr_red_scale.sensitive=false;
        var f1=new Gtk.Frame(_("Red Threshold %"));
        f1.add(_thr_red_scale);
        vb.pack_start(f1,false, true, 0);

        _thr_green_scale=new Scale.with_range(Gtk.Orientation.HORIZONTAL,0.00,1.00,0.01);
        //_thr_green_scale.set_update_policy(Gtk.UpdateType.DISCONTINUOUS);
        _thr_green_scale.width_request=200;
        _thr_green_scale.sensitive=false;
        var f2=new Gtk.Frame(_("Green Threshold"));
        f2.add(_thr_green_scale);
        vb.pack_start(f2,false, true, 0);

        _thr_blue_scale=new Scale.with_range(Gtk.Orientation.HORIZONTAL,0.00,1.00,0.01);
        //_thr_blue_scale.set_update_policy(Gtk.UpdateType.DISCONTINUOUS);
        _thr_blue_scale.width_request=200;
        _thr_blue_scale.sensitive=false;
        var f3=new Gtk.Frame(_("Blue threshold"));
        f3.add(_thr_blue_scale);
        vb.pack_start(f3,false, true, 0);

        _thr_alpha_scale=new Scale.with_range(Gtk.Orientation.HORIZONTAL,0.00,1.00,0.01);
        //_thr_alpha_scale.set_update_policy(Gtk.UpdateType.DISCONTINUOUS);
        _thr_alpha_scale.width_request=200;
        _thr_alpha_scale.sensitive=false;
        var f4=new Gtk.Frame(_("Alpha threshold"));
        f4.add(_thr_alpha_scale);
        vb.pack_start(f4,false, true, 0);

        var f5=new Gtk.Frame(_("Image information"));
        //var vb2=new VBox(true,2);
        var vb2=new Box(Gtk.Orientation.VERTICAL,2); vb2.set_homogeneous(true);
        _ht_label=new Gtk.Label(_("Height:"));
        _wd_label=new Gtk.Label(_("Width:"));
        _bts_label=new Gtk.Label(_("Bits/sample:"));
        _channels_label=new Gtk.Label(_("Channels:"));
        vb2.add(_ht_label);
        vb2.add(_wd_label);
        vb2.add(_bts_label);
        vb2.add(_channels_label);
        f5.add(vb2);
        vb.pack_start(f5,false, true, 0);


        hb.pack_start(vb,false, true, 0);
        var vbox=(Gtk.Box)(this.get_content_area());
        vbox.pack_start(hb,true,true,3);
        this.add_buttons(Gtk.Stock.OK, Gtk.ResponseType.OK, Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);

        _okbutton=this.get_widget_for_response(Gtk.ResponseType.OK);
        _okbutton.set_sensitive(false);

        set_sliders_to_default_values();

        load_button.clicked.connect(load_image);
        _monocheckbutton.toggled.connect((w)=>{
        _zoom.sensitive=w.active;
            _invertcheckbutton.sensitive=w.active;
            _thr_red_scale.sensitive=w.active;
            _thr_green_scale.sensitive=w.active;
            _thr_blue_scale.sensitive=w.active;
            _thr_alpha_scale.sensitive=w.active;
            display_image();
        });
        _invertcheckbutton.toggled.connect(display_image);
        _zoom.value_changed.connect(display_image);
        _thr_red_scale.value_changed.connect(display_image);
        _thr_green_scale.value_changed.connect(display_image);
        _thr_blue_scale.value_changed.connect(display_image);
        _thr_alpha_scale.value_changed.connect(display_image);

        load_image();
    }

    private void set_sliders_to_default_values()
    {
        _zoom.set_value(100.0);
        _thr_red_scale.set_value(0.5);
        _thr_green_scale.set_value(0.5);
        _thr_blue_scale.set_value(0.5);
        _thr_alpha_scale.set_value(0.0);
    }

    private void load_image()
    {
        _zoom.set_value(100.0);
        string fn=get_image_filename();

        if (fn=="") return;

        _name=Utils.get_stripped_basename(fn,null);
        if (_name.has_suffix("png")||_name.has_suffix("bmp")||_name.has_suffix("svg"))
        {
            if (load_image_file(fn)) display_image();
            else
            {
                Utils.show_error_dialog(_("Failed to load image"));
            }
        }
        else
        {
            Utils.show_error_dialog(_("File type not supported - use PNG, BMP or SVG"));
        }
    }

    private string get_image_filename()
    {
        string[] filternames = {"PNG Image files","Bitmap Image files","SVG Image Files","All files"};
        string[] filters={"*.png","*.bmp","*.svg","*.*"};
        string image_filename=Utils.get_file_path(FileChooserAction.OPEN,_("Select an image to convert"),filternames, filters, Environment.get_current_dir());
        return image_filename;
    }

    private bool load_image_file(string filename)
    {
        try
        {
            _pbo=new Gdk.Pixbuf.from_file(filename);
            _monocheckbutton.sensitive=true;
            set_sliders_to_default_values();
        }
        catch (GLib.Error e)
        {
            return false;
        }
        return true;
    }

    private void display_image()
    {
        if(_monocheckbutton.active)
        {
            to_mono();
            zoom_mono();
            if(_pbs==null)
            {
                return;
            }
            if (!(_pbs is Gdk.Pixbuf))
            {
                return;
            }
            _img.pixbuf=_pbs.scale_simple(300,(300*_pbs.height/_pbs.width),Gdk.InterpType.NEAREST);
            show_props(_pbs);
        }
        else
        {
            if(_pbo==null)
            {
                return;
            }
            if (!(_pbo is Gdk.Pixbuf))
            {
                return;
            }
            _img.pixbuf=_pbo.scale_simple(300,(300*_pbo.height/_pbo.width),Gdk.InterpType.NEAREST);
            show_props(_pbo);
        }
    }

    private void zoom_mono()
    {
        if(_pbm==null)
        {
            return;
        } //no mono image loaded
        if (!(_pbm is Gdk.Pixbuf))
        {
            return;
        }
        double ratio=_zoom.get_value()/100.0;
        _pbs=_pbm.scale_simple((int)(_pbm.width*ratio), (int)(_pbm.height*ratio), Gdk.InterpType.NEAREST);
    }

    private void to_mono()
    {
        if (_pbo==null)
        {
            return;
        }
        if (_pbo.bits_per_sample!=8 || _pbo.n_channels<3)
        {
            Utils.show_warning_dialog(_("Cannot convert this image format; need 8 bits per channel and at least 3 channels"));
            return;
        }

        int channels=_pbo.n_channels;
        bool has_alpha=_pbo.has_alpha;
        int width=_pbo.width;
        int height=_pbo.height;
        int rowstride=_pbo.rowstride;

        uint8 white=_invertcheckbutton.active ? 0 : 255;
        uint8 black=255-white;

        _pbm=_pbo.copy();

//      Pixdata pixdata=Gdk.Pixdata();
//      pixdata.from_pixbuf(_pbm,false);
//      unowned uint8[] pix=pixdata.pixel_data;
        unowned uint8[] pix=_pbm.get_pixels();

        int idx=0;
        int row=0;
        int a=255;
        int thr_r=(int)((_thr_red_scale.get_value())*255);
        int thr_g=(int)((_thr_green_scale.get_value())*255);
        int thr_b=(int)((_thr_blue_scale.get_value())*255);
        int thr_a=(int)((_thr_alpha_scale.get_value())*255);

        for (int h=0;h<height;h++)
        {
            for (int w=0;w<width;w++)
            {
                if (has_alpha) a=pix[idx+3];
                else a=1;
                if ((pix[idx]<thr_r||pix[idx+1]<thr_g||pix[idx+2]<thr_b) && a>thr_a)
                {
                    pix[idx]=black;
                    pix[idx+1]=black;
                    pix[idx+2]=black;
                }
                else
                {
                    pix[idx]=white;
                    pix[idx+1]=white;
                    pix[idx+2]=white;
                }
                if (has_alpha) pix[idx+3]=255;
                idx+=channels;
            }
            row+=1;
            idx=row*rowstride;
        }
    }

    public int get_rows()
    {
        return _pbs.height;
    }

    public int get_cols()
    {
        return _pbs.width;
    }

    public CellState[] get_state_array(int row)
    {
        int start=row*_pbs.rowstride;
        int channels=_pbs.n_channels;

        CellState[] cs=new CellState[_pbs.width];

//      Pixdata pixdata=Gdk.Pixdata();
//      pixdata.from_pixbuf(_pbs,false);
//      unowned uint8[] pix=pixdata.pixel_data;
        unowned uint8[] pix=_pbs.get_pixels();

        for (int i=0;i<_pbs.width;i++)
        {
            cs[i]= (CellState)(pix[start+i*channels]<128 ? 2 : 1);
        }
        return cs;
    }

    private void show_props(Gdk.Pixbuf pb=_pbs)
    {
        _ht_label.label=_("Height: ")+@"$(pb.height)";
        _wd_label.label=_("Width: ")+@"$(pb.width)";
        _bts_label.label= _("Bits/sample: ")+@"$(pb.bits_per_sample)";
        _channels_label.label=_("Channels: ")+@"$(pb.n_channels)";

                _okbutton.set_sensitive(pb.height<=Resource.MAXSIZE && pb.width<=Resource.MAXSIZE);
    }

    public string get_name()
    {
        return _name;
    }
}
