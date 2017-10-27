project ('com.github.jeremypw.gnonograms-elementary', 'vala', 'c')
shortname = 'gnonograms-elementary'
domain = 'com.github.jeremypw.'

add_project_arguments (
    ['--vapidir', join_paths (meson.current_source_dir (), 'vapi')],
    language: 'vala'
)

i18n = import ('i18n')

add_global_arguments (
    '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
    language:'c'
)

conf_data = configuration_data ()
conf_data.set ('VERSION', '1.0')
conf_data.set ('DATADIR', join_paths (get_option ('prefix'), get_option ('datadir')))
conf_data.set ('PKGDATADIR', join_paths (get_option ('prefix'), get_option ('datadir'), meson.project_name ()))
conf_data.set ('PROJECT_NAME', meson.project_name ())
conf_data.set ('PROGRAM_NAME', shortname)

configure_file (input : 'config.h.meson',
                output : 'config.h',
                configuration : conf_data )

executable (
    meson.project_name (),
    'src/gnonograms.vala',
    'src/Gnonogram_controller.vala',
    'src/Gnonogram_view.vala',
    'src/widgets/Gnonogram_labelbox.vala',
    'src/widgets/Gnonogram_label.vala',
    'src/widgets/Gnonogram_cellgrid.vala',
    'src/widgets/AppMenu.vala',
    'src/widgets/ViewModeButton.vala',
    'src/widgets/Progress_indicator.vala',
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
    'vapi/config.vapi',
    dependencies : [
        dependency ('glib-2.0'),
        dependency ('gtk+-3.0'),
        dependency ('gee-0.8'),
        dependency ('granite')
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')

subdir ('po')
subdir ('data')
