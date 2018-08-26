project ('com.github.jeremypw.gnonograms', 'vala', 'c')
shortname = 'gnonograms'
domain = 'com.github.jeremypw.'
schema_path = '/com/github/jeremypw/' + shortname + '/'
tmp_dir_path = '/.local/share/' + shortname + '/'

i18n = import ('i18n')

add_global_arguments (
    '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
    language:'c'
)

dependency('gtk+-3.0', version: '>=3.18', required: true)
GTK322 = dependency('gtk+-3.0', version: '>=3.22', required: false)

if GTK322.found ()
    add_project_arguments (
        '--define=HAVE_GTK_3_22',
        language:'vala'
    )
endif

executable (
    meson.project_name (),
    'src/Application.vala',
    'src/Controller.vala',
    'src/View.vala',
    'src/RandomPatternGenerator.vala',
    'src/SimpleRandomGameGenerator.vala',
    'src/widgets/Labelbox.vala',
    'src/widgets/Label.vala',
    'src/widgets/Cellgrid.vala',
    'src/widgets/AppMenu.vala',
    'src/widgets/ViewModeButton.vala',
    'src/widgets/ProgressIndicator.vala',
    'src/core/AbstractPatternGenerator.vala',
    'src/core/AbstractGameGenerator.vala',
    'src/core/AbstractSolver.vala',
    'src/core/utils.vala',
    'src/core/Model.vala',
    'src/core/My2DCellArray.vala',
    'src/core/Range.vala',
    'src/core/Region.vala',
    'src/core/Solver.vala',
    'src/core/Filereader.vala',
    'src/core/Filewriter.vala',
    'src/core/Move.vala',
    'src/core/History.vala',
    'src/core/Enums.vala',
    'src/core/Structs.vala',
    'src/core/Constants.vala',
    dependencies : [
        dependency ('gtk+-3.0'),
        dependency ('gee-0.8'),
        dependency ('granite')
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')

uninstall_data = configuration_data()
uninstall_data.set('schema_install_dir', join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas'))
uninstall_data.set('schema_path', schema_path)
uninstall_data.set('tmp_dir_path', tmp_dir_path)
uninstall_data.set('icon_dir_path', join_paths(get_option('prefix'), get_option('datadir'), 'icons', 'hicolor'))
uninstall_data.set('mime_dir_path', join_paths(get_option('prefix'), get_option('datadir'), 'mime', 'packages'))
uninstall_data.set('desktop_dir_path', join_paths(get_option('prefix'), get_option('datadir'), 'applications'))

configure_file (
    input: join_paths (meson.source_root (), 'data', 'post_uninstall.py.in'),
    output: 'post_uninstall.py',
    configuration: uninstall_data
)

subdir ('po')
subdir ('data')
