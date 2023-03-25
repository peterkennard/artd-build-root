cmake_minimum_required(VERSION 3.24)
project ("artdlib")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if(APPLE)
    # this is for vulkan and mac environments ( TBD cleaned up )
    include_directories("/usr/local/include" "/opt/homebrew/include")
elseif(WIN32)

    if(DEFINED ENV{VULKAN_SDK})
        include_directories("$ENV{VULKAN_SDK}/include")
    endif()

endif()

add_subdirectory ("artdlib-cpp")
add_subdirectory ("artdlib-test")
add_subdirectory ("third-party")
