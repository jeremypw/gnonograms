project (
    'com.github.jeremypw.gnonograms',
    'vala', 'c',
    version: '4.0.0',
    meson_version: '>= 0.58.0'
)

vala_version_required = '>=0.56.0'

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

if get_option('with_debugging')
    add_project_arguments('--define=WITH_DEBUGGING', language: 'vala')
endif

i18n = import ('i18n')
gnome = import('gnome')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_data.set_quoted('VERSION', meson.project_version())
config_data.set_quoted('APP_ID', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

gnonogram_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4', version: '>=4.10'),
    dependency('gee-0.8', version: '>=0.8.5'),
    dependency('granite-7'),
    dependency('libadwaita-1')
]

executable (
    meson.project_name (),
    'src/Application.vala',
    'src/Controller.vala',
    'src/View.vala',
    'src/HeaderBar/HeaderButton.vala',
    'src/HeaderBar/PopoverButton.vala',
    'src/HeaderBar/ProgressIndicator.vala',
    'src/HeaderBar/RestartButton.vala',
    'src/HeaderBar/AppPopover.vala',
    'src/HeaderBar/PreferencesDialog.vala',
    'src/HeaderBar/PreferenceRow.vala',
    'src/services/RandomPatternGenerator.vala',
    'src/services/RandomGameGenerator.vala',
    'src/services/ShortcutHelper.vala',
    'src/ui/shortcuthelper.ui.vala',
    'libcore/widgets/Cluebox.vala',
    'libcore/widgets/Clue.vala',
    'libcore/widgets/Cellgrid.vala',
    'libcore/widgets/CellPattern.vala',
    'libcore/utils.vala',
    'libcore/Model.vala',
    'libcore/My2DCellArray.vala',
    'libcore/Region.vala',
    'libcore/Solver.vala',
    'libcore/Filereader.vala',
    'libcore/Filewriter.vala',
    'libcore/Move.vala',
    'libcore/History.vala',
    'libcore/Enums.vala',
    'libcore/Structs.vala',
    'libcore/Constants.vala',
    config_file,
    dependencies : gnonogram_deps,
    install: true
)

subdir ('po')
subdir ('data')

gnome.post_install(glib_compile_schemas: true)
