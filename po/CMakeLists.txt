include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/com.github.jeremypw.gnonograms-elementary.desktop.in
    APPDATA_FILES
        ../data/gnonograms-elementary.appdata.xml.in
)
