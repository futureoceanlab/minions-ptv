project(ptvSimulations)
 
cmake_minimum_required(VERSION 2.6)
set(CMAKE_CXX_STANDARD 11)

find_package(PkgConfig REQUIRED)
find_package(OpenCV REQUIRED)

include_directories( ${CMAKE_CURRENT_BINARY_DIR}  ${OpenCV_INCLUDE_DIRS} )

add_executable(ptvSimulations simulations.cpp)

target_link_libraries(ptvSimuations  ${OpenCV_LIBS} )

install(TARGETS ptvSimulations RUNTIME DESTINATION bin)
 