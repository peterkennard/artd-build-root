

cmake_minimum_required(VERSION 3.24)
project ("artdlib-cpp")

add_subdirectory ("artd-lib-logger")
add_subdirectory ("artd-jlib-base")
add_subdirectory ("artd-jlib-thread")

# oh my so much easier to do in rake - one needs to establish a dependency
# graph to make sure all the needed parts for each module are present.

if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artd-jlib-io")
    add_subdirectory ("artd-jlib-io")
    add_subdirectory ("artd-lib-vecmath")

    if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artd-jlib-util")
        add_subdirectory ("artd-jlib-util")

        if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artd-jlib-net")
            add_subdirectory ("artd-jlib-net")
        endif()

        if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artd-gpu-engine")
            add_subdirectory ("artd-gpu-engine")
        endif()
    endif()

endif()
