cmake_minimum_required(VERSION 3.24)
project ("artd-root")

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/build-scripts/cmake-files" )

set(CMAKE_CXX_STANDARD 17)
if(NOT WIN32)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include_directories(./build/include)

add_subdirectory ("./native-libs")
add_subdirectory ("./third-party")
