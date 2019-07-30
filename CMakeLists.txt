cmake_minimum_required(VERSION 3.8)
project(darkapp)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 11)

find_package(Darknet CONFIG REQUIRED)

add_executable(darkapp ${CMAKE_CURRENT_LIST_DIR}/src/main.cpp)
target_link_libraries(darkapp PRIVATE Darknet::dark)
install(TARGETS darkapp DESTINATION ${CMAKE_CURRENT_LIST_DIR}/bin)
