# Locate the FBX SDK (version 2013.1 only atm)
#
# Defines the following variables:
#
#    FBX_FOUND - Found the FBX SDK
#    FBX_VERSION - Version number
#    FBX_INCLUDE_DIRS - Include directories
#    FBX_LIBRARIES - The libraries to link to
#
# Accepts the following variables as input:
#
#    FBX_VERSION - as a CMake variable, e.g. 2014.1
#    FBX_ROOT - (as a CMake or environment variable)
#               The root directory of the FBX SDK install

set( FBX_NOT_FOUND_MESSAGE "Unable to find FBX SDK, be sure to install it." )

if(NOT FBX_VERSION)
    set(FBX_VERSION 2015.1)
endif()
string(REGEX REPLACE "^([0-9]+).*$" "\\1" FBX_VERSION_MAJOR "${FBX_VERSION}")
string(REGEX REPLACE "^[0-9]+\\.([0-9]+).*$" "\\1" FBX_VERSION_MINOR  "${FBX_VERSION}")
string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.([0-9]+).*$" "\\1" FBX_VERSION_PATCH "${FBX_VERSION}")

set(FBX_MAC_LOCATIONS
    "/Applications/Autodesk/FBX\ SDK/${FBX_VERSION}"
)

if(WIN32)
    string(REGEX REPLACE "\\\\" "/" WIN_PROGRAM_FILES_X64_DIRECTORY $ENV{ProgramW6432})
endif()

set(FBX_WIN_LOCATIONS
    "${WIN_PROGRAM_FILES_X64_DIRECTORY}/Autodesk/FBX/FBX SDK/${FBX_VERSION}"
)

set(FBX_SEARCH_LOCATIONS
    $ENV{FBX_ROOT} ${FBX_ROOT} ${FBX_MAC_LOCATIONS} ${FBX_WIN_LOCATIONS}
)

function(_fbx_append_debugs _endvar _library)
    if(${_library} AND ${_library}_DEBUG)
        set(_output optimized ${${_library}} debug ${${_library}_DEBUG})
    else()
        set(_output ${${_library}})
    endif()
    set(${_endvar} ${_output} PARENT_SCOPE)
endfunction()

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(fbx_compiler clang)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(fbx_compiler gcc4)
endif()

function(_fbx_find_library _name _lib _suffix)
    find_library(${_name}
        NAMES ${_lib}
        HINTS ${FBX_SEARCH_LOCATIONS}
        PATH_SUFFIXES lib/${fbx_compiler}/${_suffix} lib/${fbx_compiler}/ub/${_suffix} lib/vs2013/x64/${_suffix} lib/vs2012/x64/${_suffix} lib/vs2010/x64/${_suffix} lib/vs2008/x64/${_suffix}
    )
    mark_as_advanced(${_name})
endfunction()

find_path(FBX_INCLUDE_DIR fbxsdk.h
    PATHS ${FBX_SEARCH_LOCATIONS}
    PATH_SUFFIXES include
)
mark_as_advanced(FBX_INCLUDE_DIR)

if(WIN32)
    _fbx_find_library(FBX_LIBRARY            libfbxsdk-md release)
    _fbx_find_library(FBX_LIBRARY_DEBUG      libfbxsdk-md debug)
elseif(APPLE)
    find_library(CARBON NAMES Carbon)
    find_library(SYSTEM_CONFIGURATION NAMES SystemConfiguration)
    _fbx_find_library(FBX_LIBRARY            libfbxsdk.a release)
    _fbx_find_library(FBX_LIBRARY_DEBUG      libfbxsdk.a debug)
endif()


include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(FBX ${FBX_NOT_FOUND_MESSAGE} FBX_LIBRARY FBX_INCLUDE_DIR)

if(FBX_FOUND)
    set(FBX_INCLUDE_DIRS ${FBX_INCLUDE_DIR})
    _fbx_append_debugs(FBX_LIBRARIES      FBX_LIBRARY)
    add_definitions (-DFBXSDK_NEW_API)
    if(WIN32)
        add_definitions(-DK_PLUGIN -DK_FBXSDK -DK_NODLL)
        set(CMAKE_EXE_LINKER_FLAGS /NODEFAULTLIB:\"LIBCMT\")
        set(FBX_LIBRARIES ${FBX_LIBRARIES} Wininet.lib)
    elseif(APPLE)
        set(FBX_LIBRARIES ${FBX_LIBRARIES} ${CARBON} ${SYSTEM_CONFIGURATION})
    endif()
endif()

