icon_sizes = ['32', '48', '64', '128']

foreach i : icon_sizes
    install_data (
        join_paths('icons', i, 'gnonograms-elementary.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

install_data (
    join_paths('schemas', 'apps.' + meson.project_name() + '.gschema.xml'),
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_subdir (
    'games',
    install_dir: join_paths (get_option ('datadir'), meson.project_name ())
)

i18n.merge_file (
    'desktop',
    input: 'com.github.jeremypw.' + meson.project_name () + '.meson.in.desktop',
    output: meson.project_name () + '.desktop',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'applications'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'appdata',
    input: meson.project_name () + '.meson.in.appdata.xml',
    output: meson.project_name () + '.appdata.xml',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'metainfo'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'xml'
)
