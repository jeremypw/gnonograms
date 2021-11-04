project ('com.github.jeremypw.gnonograms', 'vala', 'c', version: '1.4.3', meson_version: '>= 0.49.0')
shortname = 'gnonograms'
domain = 'com.github.jeremypw.'
schema_path = '/com/github/jeremypw/' + shortname + '/'

vala_version_required = '>=0.48.0'

i18n = import ('i18n')

add_global_arguments (
    '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
    language:'c'
)

GTK3 = dependency('gtk+-3.0', version: '>=3.22')
GEE = dependency('gee-0.8', version: '>=0.20')
GRANITE = dependency('granite', version: '>=5.2.0')
HDY = dependency('libhandy-1', version: '>=0.91.0')

gnome = import('gnome')
gresource = gnome.compile_resources(
    'gresource',
    'data/gresource.xml',
    source_dir: 'data'
)

executable (
    meson.project_name (),
    gresource,
    'src/Application.vala',
    'src/Controller.vala',
    'src/View.vala',
    'src/RandomPatternGenerator.vala',
    'src/SimpleRandomGameGenerator.vala',
    'src/widgets/AppMenu.vala',
    'src/widgets/ProgressIndicator.vala',
    'src/widgets/DimensionSpinButton.vala',
    'src/widgets/GradeChooser.vala',
    'libcore/widgets/Labelbox.vala',
    'libcore/widgets/Label.vala',
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

    dependencies : [
        GTK3,
        GEE,
        GRANITE,
        HDY
    ],

    install: true
)


meson.add_install_script('meson/post_install.py')

subdir ('po')
subdir ('data')
