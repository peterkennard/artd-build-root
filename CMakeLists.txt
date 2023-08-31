cmake_minimum_required(VERSION 3.24)
project ("artdlib")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if(APPLE)
    # this is for vulkan and mac environments ( TBD cleaned up )

# neither of these seem to work with apple Clang or Xcode projects !!!
#    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-variable -Wno-unused-parameter")
#    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-variable -Wno-unused-parameter")

#    include_directories("/usr/local/include")
#    include_directories("/usr/local/include" "/opt/homebrew/include")
elseif(WIN32)

    if(DEFINED ENV{VULKAN_SDK})
        include_directories("$ENV{VULKAN_SDK}/include")
    endif()

endif()

add_subdirectory ("artdlib-cpp")

# only if there !
if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artdlib-test")
    add_subdirectory ("artdlib-test")
endif()

add_subdirectory ("third-party")
