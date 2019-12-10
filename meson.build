project ('com.github.jeremypw.gnonograms', 'vala', 'c', version: '1.4.3', meson_version: '>= 0.42.0')
shortname = 'gnonograms'
domain = 'com.github.jeremypw.'
schema_path = '/com/github/jeremypw/' + shortname + '/'

vala_version_required = '0.34.0'

i18n = import ('i18n')

add_global_arguments (
    '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
    language:'c'
)

GTK3 = dependency('gtk+-3.0', version: '>=3.22', required: true)
GEE = dependency('gee-0.8', version: '>=0.20', required: true)
GRANITE= dependency('granite', version: '>=5.2.0', required: true)

executable (
    meson.project_name (),
    'src/Application.vala',
    'src/Controller.vala',
    'src/View.vala',
    'src/RandomPatternGenerator.vala',
    'src/SimpleRandomGameGenerator.vala',
    'src/widgets/AppMenu.vala',
    'src/widgets/ViewModeButton.vala',
    'src/widgets/ProgressIndicator.vala',
    'libcore/widgets/AbstractAppSetting.vala',
    'libcore/widgets/GradeChooser.vala',
    'libcore/widgets/ScaleGrid.vala',
    'libcore/widgets/SettingSwitch.vala',
    'libcore/widgets/TitleEntry.vala',
    'libcore/widgets/Labelbox.vala',
    'libcore/widgets/Label.vala',
    'libcore/widgets/Cellgrid.vala',
    'libcore/AbstractPatternGenerator.vala',
    'libcore/AbstractGameGenerator.vala',
    'libcore/AbstractSolver.vala',
    'libcore/utils.vala',
    'libcore/Model.vala',
    'libcore/My2DCellArray.vala',
    'libcore/Range.vala',
    'libcore/Region.vala',
    'libcore/Solver.vala',
    'libcore/Filereader.vala',
    'libcore/Filewriter.vala',
    'libcore/Move.vala',
    'libcore/History.vala',
    'libcore/Enums.vala',
    'libcore/Structs.vala',
    'libcore/Constants.vala',

    dependencies : [
        GTK3,
        GEE,
        GRANITE
    ],

    install: true
)


meson.add_install_script('meson/post_install.py')

uninstall_data = configuration_data()
uninstall_data.set('schema_install_dir', join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas'))
uninstall_data.set('schema_path', schema_path)
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
