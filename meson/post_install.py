#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')
mimetypedir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'mime')
icondir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'icons', 'hicolor')
desktopdir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'applications')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas…')
    subprocess.call(['glib-compile-schemas', schemadir])
    print('Updating icon cache…')
    subprocess.call(['gtk-update-icon-cache', '-t', '-f', icondir])
    print('Updating mimetype database…')
    subprocess.call(['update-mime-database', mimetypedir])
    print('Updating desktop database…')
    subprocess.call(['update-desktop-database', desktopdir])
