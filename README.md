# gnonograms
Nonograms puzzle game written in Vala and intended primarily for elementaryos.

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
