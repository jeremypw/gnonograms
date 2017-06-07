include (Translations)

#~ add_subdirectory (icons)
add_subdirectory (schemas)

configure_file(com.github.jeremypw.gnonograms-elementary.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop.in)

configure_file_translation(${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop ${CMAKE_SOURCE_DIR}/po/)
configure_file_translation(gnonograms-elementary.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/gnonograms-elementary.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/gnonograms-elementary.appdata.xml DESTINATION ${DATADIR}/metainfo/)

install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary.svg DESTINATION ${DATADIR}/icons/hicolor/scalable/apps)

install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/games DESTINATION ${DATADIR}/gnonograms-elementary)
