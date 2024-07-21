# include some defines automatically made by qpm
include(qpm_defines.cmake)

# Enable link time optimization
# In my experience, this can be highly unstable but it nets a huge size optimization and likely performance
# However, the instability was seen using Android.mk/ndk-build builds. With Ninja + CMake, this problem seems to have been solved.
# As always, test thoroughly
# - Fern
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

set(COMPILE_ID "ascentLanguage")

cmake_minimum_required(VERSION 3.21)
project(${COMPILE_ID})

# export compile commands for significantly better intellisense
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# c++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED 20)

# define that stores the actual source directory
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(SOURCE_INTEROP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src-interop)
set(INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(HXCPP_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/hxcpp/src)
set(HXCPP_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/hxcpp/include)

# compile options used
add_compile_options(-frtti -fexceptions -Wno-invalid-offsetof)
add_compile_options(-O3)

# recursively get all src files
RECURSE_FILES(interop_cpp_file_list ${SOURCE_INTEROP_DIR}/*.cpp)
RECURSE_FILES(haxe_cpp_file_list ${HXCPP_SOURCE_DIR}/*.cpp)
RECURSE_FILES(cpp_file_list ${SOURCE_DIR}/*.cpp)
RECURSE_FILES(c_file_list ${SOURCE_DIR}/*.c)

# add all src files to compile
add_library(
        ${COMPILE_ID}
        SHARED
        ${interop_cpp_file_list}
        ${haxe_cpp_file_list}
        ${cpp_file_list}
        ${c_file_list}
)

target_include_directories(${COMPILE_ID} PRIVATE .)

# add src dir as include dir
target_include_directories(${COMPILE_ID} PRIVATE ${SOURCE_DIR})
# add include dir as include dir
target_include_directories(${COMPILE_ID} PRIVATE ${INCLUDE_DIR})
target_include_directories(${COMPILE_ID} PRIVATE ${HXCPP_INCLUDE_DIR})
# add shared dir as include dir
target_include_directories(${COMPILE_ID} PUBLIC ${SHARED_DIR})

add_compile_definitions(HXCPP_TELEMETRY)
add_compile_definitions(HXCPP_PROFILER)
add_compile_definitions(HXCPP_DEBUGGER)
add_compile_definitions(HXCPP_M64)
add_compile_definitions(HXCPP_VISIT_ALLOCS)
add_compile_definitions(HXCPP_DLL_EXPORT)

target_link_libraries(${COMPILE_ID} PRIVATE -llog)

add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
        COMMAND ${CMAKE_STRIP} -d --strip-all
        "lib${COMPILE_ID}.so" -o "stripped_lib${COMPILE_ID}.so"
        COMMENT "Strip debug symbols done on final binary.")

add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory debug
        COMMENT "Make directory for debug symbols"
        )

add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E rename lib${COMPILE_ID}.so debug/lib${COMPILE_ID}.so
        COMMENT "Rename the lib to debug_ since it has debug symbols"
        )

# strip debug symbols from the .so and all dependencies
add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E rename stripped_lib${COMPILE_ID}.so lib${COMPILE_ID}.so
        COMMENT "Rename the stripped lib to regular"
        )
        foreach(so_file ${so_list})
        cmake_path(GET so_file FILENAME file)

        add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy ${so_file} debug/${file}
                COMMENT "Copy so files for ndk stack"
        )

        add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
                COMMAND ${CMAKE_STRIP} -g -S -d --strip-all ${so_file} -o ${file}
                COMMENT "Strip debug symbols from the dependencies")
        endforeach()

        foreach(a_file ${a_list})
        cmake_path(GET a_file FILENAME file)

        add_custom_command(TARGET ${COMPILE_ID} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${a_file} debug/${file}
        COMMENT "Copy a files for ndk stack")
        endforeach()