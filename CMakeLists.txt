project (gnonograms-elementary C)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (APP_NAME "Gnonograms")
set (EXEC_NAME "gnonograms-elementary")
set (ICON_NAME "gnonograms-elementary")
set (VERSION "0.1")
set (VERSION_INFO "Initial version for elementaryos based on version 0.9.9.3 of gnonograms3-gtk")
set (RELEASE_NAME "Create and solve gnonogram puzzles")

set (GETTEXT_PACKAGE "${EXEC_NAME}")
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/gnonograms-elementary")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)

add_definitions (-w -O3)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite)

pkg_check_modules(GDK322 QUIET gdk-3.0>=3.22)
if (GDK322_FOUND)
  set (GDK_OPTIONS --define=HAVE_GDK_3_22)
endif ()

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)

include(ValaVersion)
ensure_vala_version("0.34" MINIMUM)

add_subdirectory (data)
add_subdirectory (po)

include(ValaPrecompile)
#~ vala_precompile(VALA_C ${EXEC_NAME}
vala_precompile(VALA_C
    src/gnonograms.vala
    src/Gnonogram_controller.vala
    src/Gnonogram_view.vala
    src/widgets/Gnonogram_labelbox.vala
    src/widgets/Gnonogram_label.vala
    src/widgets/Gnonogram_cellgrid.vala
    src/widgets/AppMenu.vala
    src/widgets/ViewModeButton.vala
    src/core/utils.vala
    src/core/Gnonogram_model.vala
    src/core/My2DCellArray.vala
    src/core/Range.vala
    src/core/Gnonogram_region.vala
    src/core/Gnonogram_solver.vala
    src/core/Gnonogram_permutor.vala
    src/core/Gnonogram_filereader.vala
    src/core/Gnonogram_filewriter.vala
    src/core/Move.vala
    src/core/Enums.vala
    src/core/Structs.vala
    src/core/Constants.vala

PACKAGES
    gee-0.8
    gtk+-3.0
    granite

CUSTOM_VAPIS
    vapi/config.vapi

OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
    -g
    $(GDK_OPTIONS)
)

add_executable(${EXEC_NAME} ${VALA_C})

install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
