get_filename_component(DIRNAME "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
set(LIBRARY_NAME "${PROJECT_NAME_NO_PREFIX}_${DIRNAME}")

set(Header_Files
        "drmprocessorclientimpl.h"
        "utils_common.h"
)
source_group("Header Files" FILES "${Header_Files}")

# Common code shared by all utilities (no main())
set(Common_Source_Files
        "drmprocessorclientimpl.cpp"
        "utils_common.cpp"
)

find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(libzip REQUIRED IMPORTED_TARGET libzip)
find_package(CURL REQUIRED)

add_library("${LIBRARY_NAME}" "${Header_Files}" "${Common_Source_Files}")

target_link_libraries(
        "${LIBRARY_NAME}"
        PUBLIC
        "${PROJECT_NAME_NO_PREFIX}_compiler_flags"
        "${PROJECT_NAME_NO_PREFIX}_include"
        "PkgConfig::libzip"
        "ZLIB::ZLIB"
        "OpenSSL::SSL"
        "CURL::libcurl"
)

include(GNUInstallDirs)
target_include_directories(
        "${LIBRARY_NAME}"
        PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)

include(GenerateExportHeader)
set(_export_file "${CMAKE_CURRENT_BINARY_DIR}/${LIBRARY_NAME}_export.h")
generate_export_header("${LIBRARY_NAME}" EXPORT_FILE_NAME "${_export_file}")

set_property(TARGET "${LIBRARY_NAME}" PROPERTY VERSION "${${PROJECT_NAME}_VERSION}")
set_property(TARGET "${LIBRARY_NAME}" PROPERTY SOVERSION "${${PROJECT_NAME}_VERSION_MAJOR}")

# One executable per tool
set(UTIL_TARGETS acsmdownloader adept_activate adept_loan_mgt adept_remove launcher)
foreach(util IN LISTS UTIL_TARGETS)
    add_executable("${util}" "${util}.cpp")
    target_link_libraries("${util}" PRIVATE "${LIBRARY_NAME}" "${PROJECT_NAME_NO_PREFIX}")
    install(TARGETS "${util}" RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endforeach()

install(FILES "${_export_file}" ${Header_Files}
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
install(TARGETS "${LIBRARY_NAME}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
