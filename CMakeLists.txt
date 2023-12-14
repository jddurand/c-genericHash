#
# cmake -S c-genericHash -B c-genericHash-build
# cmake --build c-genericHash-build --config RelWithDebInfo
# ctest --test-dir c-genericHash-build -C RelWithDebInfo
# Windows:
#   cmake --install c-genericHash-build --config RelWithDebInfo --prefix %cd%/c-genericHash-install
# Others:
#   cmake --install c-genericHash-build --config RelWithDebInfo --prefix `pwd`/c-genericHash-install
# cmake --build c-genericHash-build --config RelWithDebInfo --target package
#
cmake_minimum_required(VERSION 3.26.0 FATAL_ERROR)
project(genericHash VERSION 1.0.78 LANGUAGES C)
#
# Get library helper
#
include(FetchContent)
FetchContent_Declare(cmake-helpers GIT_REPOSITORY https://github.com/jddurand/cmake-helpers.git GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(cmake-helpers)
#
# Dependencies
#
cmake_helpers_depend(genericStack
  EXTERNALPROJECT_ADD_ARGS GIT_REPOSITORY https://github.com/jddurand/c-genericStack.git GIT_SHALLOW TRUE
  FIND_PACKAGE_ARGS REQUIRED CONFIG
)
#
# Dependencies
#
cmake_helpers_depend(genericLogger
  EXTERNALPROJECT_ADD_ARGS GIT_REPOSITORY https://github.com/jddurand/c-genericLogger.git GIT_SHALLOW TRUE
  FIND_PACKAGE_ARGS REQUIRED CONFIG
)
#
# Create library
#
cmake_helpers_library(genericHash
  FIND_DEPENDENCIES "genericStack REQUIRED CONFIG"
  DEPENDS PUBLIC genericStack::genericStack
)
#
# Create test executables
#
include(CTest)
configure_file(test/config.h.in include/test/config.h)
cmake_helpers_exe(genericHashTester TEST TRUE SOURCES test/genericHash.c DEPENDS PUBLIC genericLogger::genericLogger)
#
# Package
#
cmake_helpers_package()
