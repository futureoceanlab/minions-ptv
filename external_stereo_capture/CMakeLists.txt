project(simple-snapimage)
 
cmake_minimum_required(VERSION 2.6)
set(CMAKE_CXX_STANDARD 11)

find_package(PkgConfig REQUIRED)
find_package(OpenMP REQUIRED)

set(CMAKE_BUILD_TYPE Debug)


pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0)
pkg_check_modules(TCAMLIB tcam)


include_directories( ${CMAKE_CURRENT_BINARY_DIR}  ${GSTREAMER_INCLUDE_DIRS} ${TCAM_INCLUDE_DIRS} )

add_definitions(${GSTREAMER_CFLAGS_OTHER})  

add_executable(simple-snapimage main.cpp tcamimage.cpp tcamcamera.cpp Image.cpp lodepng.cpp)
target_link_libraries(simple-snapimage ${TCAMLIB_LIBRARIES} ${GSTREAMER_LIBRARIES} ${OpenMP_CXX_FLAGS})


install(TARGETS simple-snapimage RUNTIME DESTINATION bin)
