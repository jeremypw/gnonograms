# ![icon](data/icons/48/com.github.jeremypw.gnonograms.svg) Gnonograms
Nonogram puzzle game written in Vala/Gtk.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.jeremypw.gnonograms)﻿
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Screenshot](https://raw.githubusercontent.com/jeremypw/gnonograms/master/data/screenshots/GnonogramsSolvingLight.png)

### Building and installing as Flatpak (recommended)
To build the latest code with the latest Platform and Sdk, open a terminal and navigate 
to the root folder of the source code. Then run these commands:
```
sudo apt install flatpak

flatpak remote-add --if-not-exists --system appcenter https://flatpak.elementary.io/repo.flatpakrepo

flatpak install io.elementary.Platform io.elementary.Sdk (choose 'daily' versions)

sudo apt install flatpak-builder

mkdir ./build

flatpak-builder --force-clean --install --user build com.github.jeremypw.gnonograms.yml

```

Gnonograms can be run from the terminal with
```
flatpak run com.github.jeremypw.gnonograms`
```

Gnonograms will also appear in the Applications Menu.

### Uninstalling Gnonograms Flatpak
```
flatpak uninstall com.github.jeremypw.gnonograms
```

