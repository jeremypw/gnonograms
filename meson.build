project ('com.github.jeremypw.gnonograms', 'vala', 'c', version: '2.1.2', meson_version: '>= 0.49.0')

vala_version_required = '>=0.48.0'

i18n = import ('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

if get_option('with_debugging')
    add_project_arguments('--define=WITH_DEBUGGING', language: 'vala')
endif

gnome = import('gnome')
gresource = gnome.compile_resources(
    'gresource',
    'data/gresource.xml',
    source_dir: 'data'
)

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

executable (
    meson.project_name (),
    gresource,
    'src/Application.vala',
    'src/Controller.vala',
    'src/View.vala',
    'src/HeaderBar/HeaderButton.vala',
    'src/HeaderBar/ProgressIndicator.vala',
    'src/HeaderBar/RestartButton.vala',
    'src/HeaderBar/AppPopover.vala',
    'src/services/RandomPatternGenerator.vala',
    'src/services/RandomGameGenerator.vala',
    'libcore/widgets/Cluebox.vala',
    'libcore/widgets/Clue.vala',
    'libcore/widgets/Cellgrid.vala',
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

    dependencies : [
        dependency('granite-7'),
        dependency('libadwaita-1')
    ],

    install: true
)

meson.add_install_script('meson/post_install.py')

subdir ('po')
subdir ('data')
