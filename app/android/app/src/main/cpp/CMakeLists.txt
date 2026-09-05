cmake_minimum_required(VERSION 3.22.1)

project(dead_reckoning)

add_library(
    dead_reckoning
    SHARED
    dead_reckoning.cpp
)

set_target_properties(
    dead_reckoning
    PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)

target_compile_options(
    dead_reckoning
    PRIVATE
    -Wall
    -Wextra
    -O2
)