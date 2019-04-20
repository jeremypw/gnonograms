icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data (
        join_paths('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
    install_data (
        join_paths('icons', i, 'application-x-gnonogram-puzzle' + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'mimetypes')
    )
endforeach


install_data (
    join_paths('icons', meson.project_name () + '.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data (
    join_paths('icons', 'application-x-gnonogram-puzzle.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'mimetypes')
)

install_data (
    meson.project_name () + '.mimeinfo' + '.xml',
    install_dir: join_paths(get_option('datadir'), 'mime', 'packages')
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

desktop_file_validate = find_program('desktop-file-validate', required: false)

if desktop_file_validate.found()
  test (
    'Validate desktop file',
    desktop_file_validate,
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
  )
endif

appstreamcli = find_program(['appstreamcli', 'appstream-util'], required: false)

if appstreamcli.found()
  test (
    'Validate appdata file',
    appstreamcli,
    args: ['validate', '--pedantic', join_paths(meson.current_build_dir (), meson.project_name() + '.appdata.xml')]
  )
endif

gschema_file_validate = find_program ('glib-compile-schemas', required: false)

if gschema_file_validate.found()
    test (
        'Validate gschema file',
        gschema_file_validate,
        args: ['--dry-run', '--strict', join_paths (meson.current_source_dir (), 'schemas')]
    )
endif