project (gnonograms-elementary C)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (EXEC_NAME "gnonograms-elementary")
set (VERSION "0.1")
set (VERSION_INFO "Initial version for elementaryos based on version 0.9.9.3 of gnonograms3-gtk")
set (RELEASE_NAME "Create and solve gnonogram puzzles")

set (GETTEXT_PACKAGE "${EXEC_NAME}")
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/gnonograms-elementary")
set (DOLLAR "$")

set(CMAKE_BUILD_TYPE Debug)

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)

add_definitions ("-w")
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)

include(ValaVersion)
ensure_vala_version("0.34" MINIMUM)

include(ValaPrecompile)
#~ vala_precompile(VALA_C ${EXEC_NAME}
vala_precompile(VALA_C
    src/gnonograms.vala
    src/Gnonogram_controller.vala
    src/Gnonogram_view.vala
    src/widgets/Gnonogram_labelbox.vala
    src/widgets/Gnonogram_label.vala
    src/widgets/Gnonogram_cellgrid.vala
    src/widgets/DimensionControl.vala
    src/widgets/HistoryControl.vala
    #~ src/widgets/HistoryControl.vala
    src/core/utils.vala
    src/core/Gnonogram_model.vala
    src/core/My2DCellArray.vala

PACKAGES
    gtk+-3.0
    granite

CUSTOM_VAPIS
    vapi/config.vapi

OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
)

add_executable(${EXEC_NAME} ${VALA_C})

install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.yourusername.yourrepositoryname.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.yourusername.yourrepositoryname.appdata.xml DESTINATION ${DATADIR}/metainfo/)
