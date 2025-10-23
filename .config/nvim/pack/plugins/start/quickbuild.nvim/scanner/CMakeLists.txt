cmake_minimum_required(VERSION 3.15)
project(qb-scanner VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Scanner binary
add_executable(qb-scanner
    src/main.cpp
)

target_include_directories(qb-scanner PRIVATE src)

# GTest
add_subdirectory(lib/gtest)
enable_testing()

# Tests
add_executable(scanner_test
    test/scanner_test.cpp
)

target_include_directories(scanner_test PRIVATE src)
target_link_libraries(scanner_test gtest gtest_main)

add_test(NAME scanner_test COMMAND scanner_test)

# Install
install(TARGETS qb-scanner DESTINATION bin)
