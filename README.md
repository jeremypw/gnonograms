# ![icon](data/icons/48/com.github.jeremypw.gnonograms.svg) Gnonograms
Nonogram puzzle game written in Vala/Gtk and intended primarily for elementaryos.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.jeremypw.gnonograms)﻿
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Screenshot](data/screenshots/Solving.png)

### Dependencies
These dependencies must be present before building
 - `valac`
 - `meson`
 - `gtk+-3.0`
 - `granite`

 You can install these on a Ubuntu-based system by executing this command:

 `sudo apt install valac meson libgranite-dev`

### Building
```
meson build --prefix=/usr  --buildtype=release
cd build
ninja
```

### Installing & executing
```
sudo ninja install
com.github.jeremypw.gnonograms
```

### Building and installing as Flatpak
To build the latest code with the latest Platform and Sdk:
```
sudo apt install flatpak

flatpak remote-add --if-not-exists --system appcenter https://flatpak.elementary.io/repo.flatpakrepo

flatpak install io.elementary.Platform io.elementary.Sdk (choose 'daily' versions)

sudo apt install flatpak-builder

flatpak-builder --force-clean --install --user <path-to-a-build-directory> com.github.jeremypw.gnonograms.yml

```

The elementary applications menu will now contain Gnonograms or it can be run from the terminal with `flatpak run com.github.jeremypw.gnonograms.yml`
