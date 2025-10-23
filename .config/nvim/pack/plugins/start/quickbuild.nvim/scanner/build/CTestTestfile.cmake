# CMake generated Testfile for 
# Source directory: /usr/local/google/home/sauski/src/quickbuild.nvim/scanner
# Build directory: /usr/local/google/home/sauski/src/quickbuild.nvim/scanner/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(scanner_test "/usr/local/google/home/sauski/src/quickbuild.nvim/scanner/build/scanner_test")
set_tests_properties(scanner_test PROPERTIES  _BACKTRACE_TRIPLES "/usr/local/google/home/sauski/src/quickbuild.nvim/scanner/CMakeLists.txt;27;add_test;/usr/local/google/home/sauski/src/quickbuild.nvim/scanner/CMakeLists.txt;0;")
subdirs("lib/gtest")
