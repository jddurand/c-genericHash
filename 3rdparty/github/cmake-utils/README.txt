# cmake-utils - CMake macros customized for /my/ packages
#
# These macros are trying to reduce CMake scripting up to functional roles only.
#
# All technical CMake subtilities are hiden.
#
# Typical usage is:
#

CMAKE_MINIMUM_REQUIRED (VERSION 3.26.0 FATAL_ERROR)
PROJECT(cmake_utils VERSION 1.0.11 LANGUAGES C CXX)
IF (NOT MYPACKAGEBOOTSTRAP_DONE)
  #############
  # Bootstrap #
  #############
  INCLUDE ("../cmake/MyPackageBootstrap.cmake")
ENDIF ()

#########
# Start #
#########
MYPACKAGESTART ()

###########
# library #
###########
MYPACKAGELIBRARY(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in
  ${INCLUDE_OUTPUT_PATH}/test/internal/config.h
  src/test.c)

#########################
# Personal dependencies #
#########################
IF (CMAKE_MATH_LIBS)
  FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
    TARGET_LINK_LIBRARIES(${_target} PUBLIC ${CMAKE_MATH_LIBS})
  ENDFOREACH ()
ENDIF ()

###############
# Executables #
###############
MYPACKAGEEXECUTABLE(executable bin/executable.c)
MYPACKAGETESTEXECUTABLE(test_executable bin/executable.c)

#########
# Tests #
#########
MYPACKAGECHECK(test_executable)

##########
# Export #
##########
MYPACKAGECMAKEEXPORT()
MYPACKAGEPKGCONFIGEXPORT()

#############
# Packaging #
#############
MYPACKAGEPACK("Vendor" "Summary")

#########
# Setup #
#########
MYPACKAGEPRINTSETUP()
