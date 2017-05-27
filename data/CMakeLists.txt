include (Translations)

#~ add_subdirectory (icons)
add_subdirectory (schemas)

configure_file(com.github.jeremypw.gnonograms-elementary.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop.in)

configure_file_translation(${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop ${CMAKE_SOURCE_DIR}/po/)
configure_file_translation(gnonograms-elementary.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/gnonograms-elementary.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/com.github.jeremypw.gnonograms-elementary.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/gnonograms-elementary.appdata.xml DESTINATION ${DATADIR}/metainfo/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary.svg DESTINATION ${DATADIR}/icons/hicolor/scalable/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary-256.png DESTINATION ${DATADIR}/icons/hicolor/256/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary-128.png DESTINATION ${DATADIR}/icons/hicolor/128/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary-96.png DESTINATION ${DATADIR}/icons/hicolor/96/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary-64.png DESTINATION ${DATADIR}/icons/hicolor/64/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary-48.png DESTINATION ${DATADIR}/icons/hicolor/48/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary-32.png DESTINATION ${DATADIR}/icons/hicolor/32/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/gnonograms-elementary.svg DESTINATION ${DATADIR}/icons/elementary/apps/128)
