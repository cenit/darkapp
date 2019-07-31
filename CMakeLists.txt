cmake_minimum_required(VERSION 3.8)
project(darkapp)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 11)

find_package(Darknet CONFIG REQUIRED)

add_executable(darkapp ${CMAKE_CURRENT_LIST_DIR}/src/empty_test.cpp)
target_link_libraries(darkapp PRIVATE Darknet::dark)
add_executable(darknet ${CMAKE_CURRENT_LIST_DIR}/src/darknet.c)
target_link_libraries(darknet PRIVATE Darknet::dark)
add_executable(yolocpp ${CMAKE_CURRENT_LIST_DIR}/src/yolo_console_dll.cpp)
target_link_libraries(yolocpp PRIVATE Darknet::dark)
install(TARGETS darkapp darknet yolocpp DESTINATION ${CMAKE_CURRENT_LIST_DIR}/bin)
