#
# Multi-config generator, e.g. Visual Studio on Windows:
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
# Single-config generator, e.g. NMake Makefiles on Windows, Unix Makefiles on Linxu:
#
# cmake -S c-genericHash -B c-genericHash-build -DCMAKE_BUILD_TYPE=RelWithDebInfo
# cmake --build c-genericHash-build
# ctest --test-dir c-genericHash-build
# Windows:
#   cmake --install c-genericHash-build --prefix %cd%/c-genericHash-install
# Others:
#   cmake --install c-genericHash-build --prefix `pwd`/c-genericHash-install
# cmake --build c-genericHash-build --target package
#
cmake_minimum_required(VERSION 3.26.0 FATAL_ERROR)
project(genericHash VERSION 1.0.79 LANGUAGES C)
#
# Get library helper
#
include(FetchContent)
FetchContent_Declare(cmake-helpers GIT_REPOSITORY https://github.com/jddurand/cmake-helpers.git GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(cmake-helpers)
#
# Dependencies
#
set(genericHash_depends)
set(genericHash_depends_ext)
set(genericHash_find_dependencies)
#
# genericStack: public dependency
#
set(genericStack_git https://github.com/jddurand/c-genericStack.git)
cmake_helpers_depend(genericStack
  EXTERNALPROJECT_ADD_ARGS
    GIT_REPOSITORY ${genericStack_git}
    GIT_SHALLOW TRUE
  FIND_PACKAGE_ARGS
    REQUIRED CONFIG
)
list(APPEND marpaESLIF_find_dependencies "genericStack REQUIRED CONFIG")
list(APPEND marpaESLIF_depends PUBLIC genericStack::genericStack)
#
# Dependencies: test dependency
#
set(genericLogger_git https://github.com/jddurand/c-genericLogger.git)
cmake_helpers_depend(genericLogger
  EXTERNALPROJECT_ADD_ARGS
    GIT_REPOSITORY ${https://github.com/jddurand/c-genericLogger.git}
    GIT_SHALLOW TRUE
  FIND_PACKAGE_ARGS
    REQUIRED CONFIG
)
#
# Create library
#
cmake_helpers_library(genericHash
  FIND_DEPENDENCIES ${genericHash_find_dependencies}
  DEPENDS           ${genericHash_depends}
  DEPENDS_EXT       ${genericHash_depends_ext}
)
#
# Create test executables
#
include(CTest)
configure_file(test/config.h.in include/test/config.h)
cmake_helpers_exe(genericHashTester
  TEST TRUE
  SOURCES test/genericHash.c
  DEPENDS PUBLIC genericLogger::genericLogger)
#
# Package
#
cmake_helpers_package()
