icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data (
        join_paths('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
    install_data (
        join_paths('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )
endforeach


install_data (
    join_paths('icons', meson.project_name () + '.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data (
    join_paths('icons', '32', 'head-thinking.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '32x32', 'actions')
)

install_data (
    join_paths('icons', '32', 'head-thinking.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '32x32@2', 'actions')
)

install_data (
    join_paths (meson.current_source_dir (),'schemas', meson.project_name() + '.gschema.xml'),
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file (
    'desktop',
    input: meson.project_name () + '.desktop.in',
    output: meson.project_name () + '.desktop',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'applications'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'appdata',
    input: meson.project_name () + '.appdata.xml.in',
    output: meson.project_name () + '.appdata.xml',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'metainfo'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'xml'
)
