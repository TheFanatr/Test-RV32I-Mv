cmake_minimum_required(VERSION 3.26)
project(fmax C CXX)

SET(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -std=c++23 -g")
SET(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -g")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
#
# parser GUI
file(GLOB_RECURSE MYWAVE_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/src/*.cpp")

add_executable(fmax)
target_sources(fmax PRIVATE ${PROJECT_SOURCES} ${MYWAVE_SOURCES})
target_include_directories(fmax
        PRIVATE
        /usr/share/yosys/include/
        src)
target_link_libraries(fmax PRIVATE /usr/lib/yosys/libyosys.so ${libs})
