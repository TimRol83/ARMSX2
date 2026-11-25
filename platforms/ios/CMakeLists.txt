cmake_minimum_required(VERSION 3.22)
set(CMAKE_SYSTEM_PROCESSOR "arm64" CACHE STRING "" FORCE)
project(ARMSX2iOS LANGUAGES C CXX OBJC OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0" CACHE STRING "" FORCE)
set(TOP_CMAKE_WAS_SOURCED TRUE)

option(ARMSX2_CORE_ONLY "Build only core static libraries" OFF)
option(ARMSX2_REAL_DEVICE "Build for real iOS device" ON)
option(ARMSX2_MAC_CATALYST "Build for Mac Catalyst" OFF)
set(ARMSX2_BUNDLE_IDENTIFIER "com.armsx2.ios" CACHE STRING "")
set(ARMSX2_DEVELOPMENT_TEAM "" CACHE STRING "")
set(ARMSX2_DISPLAY_NAME "ARMSX2 iOS" CACHE STRING "")
set(ARMSX2_VERSION_SUFFIX "" CACHE STRING "")

set(ARMSX2_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" "${ARMSX2_ROOT}/cmake")

set(USE_OPENGL OFF CACHE BOOL "" FORCE)
set(USE_VULKAN OFF CACHE BOOL "" FORCE)
set(ENABLE_QT_UI OFF CACHE BOOL "" FORCE)
set(ENABLE_TESTS OFF CACHE BOOL "" FORCE)

include(Pcsx2Utils)
detect_operating_system()
detect_compiler()
include(BuildParameters)
include(SearchForStuff)
get_git_version_info()
write_svnrev_h()

add_subdirectory("${ARMSX2_ROOT}/common" "${CMAKE_CURRENT_BINARY_DIR}/common")
add_subdirectory("${ARMSX2_ROOT}/pcsx2" "${CMAKE_CURRENT_BINARY_DIR}/pcsx2")

add_custom_target(armsx2_core_libs DEPENDS PCSX2 common)

if(ARMSX2_CORE_ONLY)
  return()
endif()

enable_language(Swift)

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in" "${CMAKE_CURRENT_BINARY_DIR}/Info.plist" @ONLY)

file(GLOB_RECURSE BRIDGE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Bridge/*.m" "${CMAKE_CURRENT_SOURCE_DIR}/Bridge/*.mm")
file(GLOB_RECURSE RUNTIME_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Runtime/*.m" "${CMAKE_CURRENT_SOURCE_DIR}/Runtime/*.mm")
file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Swift/*.swift")

add_executable(ARMSX2iOS MACOSX_BUNDLE
  ${BRIDGE_SOURCES}
  ${RUNTIME_SOURCES}
  ${SWIFT_SOURCES}
)

target_include_directories(ARMSX2iOS PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/Bridge"
  "${CMAKE_CURRENT_SOURCE_DIR}/Runtime"
  "${ARMSX2_ROOT}/pcsx2"
  "${ARMSX2_ROOT}/common"
  "${ARMSX2_ROOT}/3rdparty/include"
)

target_link_libraries(ARMSX2iOS PRIVATE
  PCSX2
  common
  "-framework UIKit"
  "-framework Foundation"
  "-framework Metal"
  "-framework MetalKit"
  "-framework QuartzCore"
  "-framework GameController"
  "-framework AudioToolbox"
  "-framework AVFoundation"
  "-framework CoreGraphics"
  "-framework CoreMedia"
  "-framework CoreVideo"
  "-framework UniformTypeIdentifiers"
)

set_target_properties(ARMSX2iOS PROPERTIES
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
  XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "15.0"
  XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${ARMSX2_BUNDLE_IDENTIFIER}"
  XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/Bridge/ARMSX2-Bridging-Header.h"
  XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
  XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    XCODE_ATTRIBUTE_OTHER_CFLAGS " "
    XCODE_ATTRIBUTE_OTHER_CPLUSPLUSFLAGS " "
  XCODE_ATTRIBUTE_OTHER_SWIFT_FLAGS " "
    XCODE_ATTRIBUTE_OTHER_CFLAGS " "
    XCODE_ATTRIBUTE_OTHER_CPLUSPLUSFLAGS " "
  XCODE_ATTRIBUTE_OTHER_SWIFT_FLAGS " "
)
