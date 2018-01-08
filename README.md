# ![icon](data/icons/com.github.jeremypw.gnonograms.svg) Gnonograms
Nonogram puzzle game written in Vala/Gtk and intended primarily for elementaryos.

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Screenshot](data/screenshots/Screenshot - Solving Random.png)

### Building
```
meson build --prefix=/usr  --buildtype=release
cd build
ninja
```

### Installing & executing
```
ninja install
com.github.jeremy.gnonograms
```

### Uninstalling
```
In original build directory:

ninja uninstall
sudo ./post_uninstall.py
```
