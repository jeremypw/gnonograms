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

executable (
    meson.project_name (),
    'src/gnonograms.vala',
    'src/Gnonogram_controller.vala',
    'src/Gnonogram_view.vala',
    'src/RandomPatternGenerator.vala',
    'src/SimpleRandomGameGenerator.vala',
    'src/widgets/Gnonogram_labelbox.vala',
    'src/widgets/Gnonogram_label.vala',
    'src/widgets/Gnonogram_cellgrid.vala',
    'src/widgets/AppMenu.vala',
    'src/widgets/ViewModeButton.vala',
    'src/widgets/Progress_indicator.vala',
    'src/core/AbstractPatternGenerator.vala',
    'src/core/AbstractGameGenerator.vala',
    'src/core/AbstractSolver.vala',
    'src/core/utils.vala',
    'src/core/Gnonogram_model.vala',
    'src/core/My2DCellArray.vala',
    'src/core/Range.vala',
    'src/core/Gnonogram_region.vala',
    'src/core/Gnonogram_solver.vala',
    'src/core/Gnonogram_permutor.vala',
    'src/core/Gnonogram_filereader.vala',
    'src/core/Gnonogram_filewriter.vala',
    'src/core/Move.vala',
    'src/core/Enums.vala',
    'src/core/Structs.vala',
    'src/core/Constants.vala',
    dependencies : [
        dependency ('glib-2.0'),
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
