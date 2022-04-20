cmake_minimum_required(VERSION 3.18)

if(DEFINED ENV{VCPKG_DEFAULT_TRIPLET})
  message(STATUS "Setting default vcpkg target triplet to $ENV{VCPKG_DEFAULT_TRIPLET}")
  set(VCPKG_TARGET_TRIPLET $ENV{VCPKG_DEFAULT_TRIPLET})
endif()

if(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
  message(STATUS "VCPKG found: $ENV{VCPKG_ROOT}")
  message(STATUS "Using VCPKG integration")
elseif(DEFINED CMAKE_TOOLCHAIN_FILE)
  message(STATUS "Using toolchain: ${CMAKE_TOOLCHAIN_FILE}")
  if(CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg.cmake")
    message(STATUS "Toolchain uses VCPKG integration")
  endif()
else()
  message(WARNING "vcpkg not found, toolchain not defined, build might fail")
endif()

project(darkapp)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 11)

find_package(Darknet CONFIG REQUIRED)

add_executable(darkapp ${CMAKE_CURRENT_LIST_DIR}/src/empty_test.cpp)
target_link_libraries(darkapp PRIVATE Darknet::dark)

# this is the uselib app from official darknet repo, rebuilt here as a full example
add_executable(yolocpp ${CMAKE_CURRENT_LIST_DIR}/src/yolo_console_dll.cpp)
target_link_libraries(yolocpp PRIVATE Darknet::dark)
target_compile_definitions(yolocpp PRIVATE -DUSE_CMAKE_LIBS)

install(TARGETS darkapp yolocpp DESTINATION ${CMAKE_CURRENT_LIST_DIR}/bin)
