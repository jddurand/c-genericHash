cmake_minimum_required(VERSION 3.15 FATAL_ERROR) # For list(PREPEND ...)
#
# Based on https://stackoverflow.com/questions/44292462/how-to-auto-generate-pkgconfig-files-from-cmake-targets
#
function(auto_pc TARGET)
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-PKGCONFIG-DEBUG] Running on target ${TARGET}")
  ENDIF ()

  set(_build_dependencies ${${TARGET}_build_dependencies})
  file(CONFIGURE OUTPUT "pc.${TARGET}/CMakeLists.txt"
       CONTENT [[
cmake_minimum_required(VERSION 3.16)
project(pc_@TARGET@)

message(STATUS "[pc.@TARGET@/CMakeLists.txt] Starting")

set(CMAKE_MODULE_PATH $ENV{CMAKE_MODULE_PATH})
message(STATUS "[pc.@TARGET@/CMakeLists.txt] Using CMAKE_MODULE_PATH: \"${CMAKE_MODULE_PATH}\"")
foreach(_build_dependency @_build_dependencies@)
  list(APPEND CMAKE_PREFIX_PATH "${CMAKE_MODULE_PATH}/${_build_dependency}")
endforeach()
message(STATUS "[pc.@TARGET@/CMakeLists.txt] Using CMAKE_PREFIX_PATH: \"${CMAKE_PREFIX_PATH}\"")

message(STATUS "[pc.@TARGET@/CMakeLists.txt] Requiring config of @TARGET@ using $ENV{AUTO_PC_CMAKE_DIR}/@TARGET@Config.cmake")
include("$ENV{AUTO_PC_CMAKE_DIR}/@TARGET@Config.cmake")

#
# I do not know why $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_LINK_LIBRARIES>>,$<JOIN:$<LIST:TRANSFORM,$<TARGET_PROPERTY:INTERFACE_LINK_LIBRARIES>,REPLACE,".*::","">,>,>
# do not work
#
GET_TARGET_PROPERTY(_interface_link_libraries @TARGET@::@TARGET@ INTERFACE_LINK_LIBRARIES)
SET(_target_computed_dependencies)
FOREACH(_target ${_interface_link_libraries})
  IF (TARGET ${_target})
    GET_TARGET_PROPERTY(_target_location ${_target} LOCATION)
	cmake_path(GET _target_location FILENAME _target_filename)
	get_filename_component(_target_location_we ${_target_filename} NAME_WE)
    LIST(APPEND _target_computed_dependencies  ${_target_location_we})
  ENDIF ()
ENDFOREACH()
IF (_target_computed_dependencies)
  MESSAGE (STATUS "[pc.@TARGET@/CMakeLists.txt] Setting @TARGET@::@TARGET@ computed dependencies: ${_target_computed_dependencies}")
  SET_TARGET_PROPERTIES(@TARGET@::@TARGET@ PROPERTIES COMPUTED_DEPENDENCIES ${_target_computed_dependencies})
ENDIF ()

GET_TARGET_PROPERTY(_interface_link_libraries @TARGET@::@TARGET@_static INTERFACE_LINK_LIBRARIES)
SET(_target_computed_dependencies_static)
FOREACH(_target ${_interface_link_libraries})
  IF (TARGET ${_target})
    GET_TARGET_PROPERTY(_target_location ${_target} LOCATION)
	cmake_path(GET _target_location FILENAME _target_filename)
	get_filename_component(_target_location_we ${_target_filename} NAME_WE)
    LIST(APPEND _target_computed_dependencies_static  ${_target_location_we})
  ENDIF ()
ENDFOREACH()
IF (_target_computed_dependencies_static)
  MESSAGE (STATUS "[pc.@TARGET@/CMakeLists.txt] Setting @TARGET@::@TARGET@ static computed dependencies: ${_target_computed_dependencies_static}")
  SET_TARGET_PROPERTIES(@TARGET@::@TARGET@ PROPERTIES COMPUTED_DEPENDENCIES_STATIC ${_target_computed_dependencies_static})
ENDIF ()

MESSAGE (STATUS "[pc.@TARGET@/CMakeLists.txt] All targets: ${all_targets}")

# Cflags: $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_INCLUDE_DIRECTORIES>>,-I$<JOIN:$<TARGET_PROPERTY:INTERFACE_INCLUDE_DIRECTORIES>, -I>,> $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>>,-D$<JOIN:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>, -D>,>
# Cflags.private: $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_INCLUDE_DIRECTORIES>>,-I$<JOIN:$<TARGET_PROPERTY:INTERFACE_INCLUDE_DIRECTORIES>, -I>,> $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>>,-D$<JOIN:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>, -D>,> -D@TARGET@_STATIC
# Libs: $<TARGET_LINKER_FILE_DIR:@TARGET@::@TARGET@>/$<TARGET_LINKER_FILE_NAME:@TARGET@::@TARGET@>
# Libs.private: $<TARGET_LINKER_FILE_DIR:@TARGET@::@TARGET@_static>/$<TARGET_LINKER_FILE_NAME:@TARGET@::@TARGET@_static>

message(STATUS "[pc.@TARGET@/CMakeLists.txt] Generating ${CMAKE_CURRENT_BINARY_DIR}/@TARGET@.pc")
file(GENERATE OUTPUT @TARGET@.pc
     CONTENT [=[
prefix=${pcfiledir}/../..
exec_prefix=${prefix}
bindir=${exec_prefix}/@CMAKE_INSTALL_BINDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@
docdir=${prefix}/@CMAKE_INSTALL_DOCDIR@
libdir=${exec_prefix}/@CMAKE_INSTALL_LIBDIR@
mandir=${prefix}/@CMAKE_INSTALL_MANDIR@
man1dir=${prefix}/@CMAKE_INSTALL_MANDIR@1
man2dir=${prefix}/@CMAKE_INSTALL_MANDIR@2

Name: @TARGET@
Requires: $<IF:$<BOOL:$<TARGET_PROPERTY:COMPUTED_DEPENDENCIES>>,$<JOIN:$<TARGET_PROPERTY:COMPUTED_DEPENDENCIES>,>,>
Requires.private: $<IF:$<BOOL:$<TARGET_PROPERTY:COMPUTED_DEPENDENCIES_STATIC>>,$<JOIN:$<TARGET_PROPERTY:COMPUTED_DEPENDENCIES_STATIC>,>,>
Cflags: -I${includedir} $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>>,-D$<JOIN:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>, -D>,>
Cflags.private: -D@TARGET@_STATIC -I${includedir} $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>>,-D$<JOIN:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>, -D>,>
Libs: -L${libdir} -l@TARGET@
Libs.private: -L${libdir} $<TARGET_LINKER_FILE_NAME:@TARGET@::@TARGET@_static>
]=]   TARGET "@TARGET@::@TARGET@")
]] @ONLY NEWLINE_STYLE LF)

  file(CONFIGURE OUTPUT "pc.${TARGET}/post-install.cmake"
    CONTENT [[
file(REAL_PATH "$ENV{CMAKE_CURRENT_SOURCE_DIR}" cmake_install_prefix)
file(REAL_PATH "$ENV{CMAKE_INSTALL_LIBDIR}" cmake_install_libdir)
set(AUTO_PC_CMAKE_DIR "${cmake_install_libdir}/cmake/@TARGET@")
set(AUTO_PC_PKGCONFIG_DIR "${cmake_install_libdir}/pkgconfig")
file(REAL_PATH "@CMAKE_BINARY_DIR@" cmake_binary_dir) # Top-level binary dir
file(REAL_PATH "@CMAKE_CURRENT_BINARY_DIR@" cmake_current_binary_dir)

set(proj "${cmake_current_binary_dir}/pc.@TARGET@")
set(ENV{AUTO_PC_CMAKE_DIR} ${AUTO_PC_CMAKE_DIR})
set(ENV{AUTO_PC_PKGCONFIG_DIR} ${AUTO_PC_PKGCONFIG_DIR})
set(ENV{AUTO_PC_INSTALL_PREFIX} ${cmake_install_prefix})
execute_process(COMMAND "@CMAKE_COMMAND@" -G "@CMAKE_GENERATOR@" -S "${proj}" -B "${proj}/build")
message(STATUS "[pc.@TARGET@/post-install.cmake] Creating ${AUTO_PC_PKGCONFIG_DIR}/@TARGET@.pc")
#
# Revisit paths: CMake auto-discovery will set:
# -I<include path> to full current path
# -L<library path> to full library path
file(READ "${proj}/build/@TARGET@.pc" PC)
# message(STATUS "Replacing -I${cmake_install_prefix}/include")
# string(REPLACE "-I${cmake_install_prefix}/include" "" PC ${PC})
#
# On UNIX this will be .../libXXX.etc
# On Windows this will be .../libXXX.lib
# message(STATUS "Replacing ${cmake_install_libdir}")
# string(REPLACE "${cmake_install_libdir}" "" PC ${PC})
# file(WRITE ${AUTO_PC_PKGCONFIG_DIR}/@TARGET@.pc ${PC})
file(COPY "${proj}/build/@TARGET@.pc" DESTINATION ${AUTO_PC_PKGCONFIG_DIR})
]] @ONLY NEWLINE_STYLE LF)

  GET_PROPERTY(remaining_post_installs GLOBAL PROPERTY MYPACKAGE_REMAINING_POST_INSTALLS)
  IF (NOT DEFINED remaining_post_installs)
    set (remaining_post_installs 1)
  ELSE ()
    math(EXPR remaining_post_installs "${remaining_post_installs} + 1")
  ENDIF ()
  message(STATUS "Number of post-installs: ${remaining_post_installs}")
  SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_REMAINING_POST_INSTALLS ${remaining_post_installs})
  #
  # We initialize the post-install counter only on the top-level project
  # We intentionaly overwrite CMAKE_BINARY_DIR and not CMAKE_CURRENT_BINARY_DIR
  #
  SET (REMAINING_POST_INSTALLS_PATH ${CMAKE_BINARY_DIR}/remaining_post_installs.txt)
  IF (CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    INSTALL (CODE "FILE(WRITE ${REMAINING_POST_INSTALLS_PATH} \"${remaining_post_installs}\")")
  ENDIF ()
  #
  SET (FIRE_POST_INSTALL_CMAKE_PATH ${CMAKE_BINARY_DIR}/fire_post_installs.cmake)
  IF (remaining_post_installs EQUAL 1)
    #
    # First time: initialize fire_post_installs.cmake
    #
    FILE(WRITE ${FIRE_POST_INSTALL_CMAKE_PATH} [[]])
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_MODULE_PATH \$ENV{CMAKE_MODULE_PATH})\n")
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"Using CMAKE_MODULE_PATH=\\\"\${CMAKE_MODULE_PATH}\\\"\")\n")
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_INSTALL_PREFIX \$ENV{CMAKE_INSTALL_PREFIX})\n")
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"Using CMAKE_INSTALL_PREFIX=\\\"\${CMAKE_INSTALL_PREFIX}\\\"\")\n")
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_INSTALL_LIBDIR \$ENV{CMAKE_INSTALL_LIBDIR})\n")
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"Using CMAKE_INSTALL_LIBDIR=\\\"\${CMAKE_INSTALL_LIBDIR}\\\"\")\n")
  ENDIF ()
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_MODULE_PATH_ORIG \${CMAKE_MODULE_PATH})\n")
  FOREACH(_public_dependency ${${TARGET}_public_dependencies})
    FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "list(APPEND CMAKE_MODULE_PATH \"\${CMAKE_MODULE_PATH_ORIG}/${_public_dependency}\")\n")
  ENDFOREACH()
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "include(${CMAKE_CURRENT_BINARY_DIR}/pc.${TARGET}/post-install.cmake)\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_MODULE_PATH \${CMAKE_MODULE_PATH_ORIG})\n")
  #
  # At each install we decrement the number of remaining post installs, and fire all of them when the number is 0
  # We CANNOT use CMAKE_INSTALL_PREFIX variable contrary to what is posted almost everywhere on the net: CPack will
  # will have a CMAKE_INSTALL_PREFIX different, the real and only way to know exactly where we install things is to
  # set the current working directory to $DESTDIR/$CMAKE_INSTALL_PREFIX, and use WORKING_DIRECTORY as the full install prefix dir.
  #
  INSTALL(CODE "
    set(CPACK_IS_RUNNING \$ENV{CPACK_IS_RUNNING})
    #
    # Prevent a warning from GNUInstallDirs, unfortunately enable_language() is not scriptable ;)
    #
    set(CMAKE_SYSTEM_NAME ${CMAKE_SYSTEM_NAME})
    set(CMAKE_SIZEOF_VOID_P ${CMAKE_SIZEOF_VOID_P})
    include(GNUInstallDirs)
    #
    # We do not want to run this when it is CPack
    #
    if (NOT CPACK_IS_RUNNING)
      file(READ \"${REMAINING_POST_INSTALLS_PATH}\" remaining_post_installs)
      math(EXPR remaining_post_installs \"\${remaining_post_installs} - 1\")
      FILE(WRITE \"${REMAINING_POST_INSTALLS_PATH}\" \"\${remaining_post_installs}\")
      message(STATUS \"Remaining post-installs: \${remaining_post_installs}\")
      if (remaining_post_installs LESS_EQUAL 0)
        message(STATUS \"Firing post-installs\")
        set(ENV{CMAKE_INSTALL_PREFIX} \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}\")
        set(ENV{CMAKE_INSTALL_LIBDIR} \${CMAKE_INSTALL_LIBDIR})
        execute_process(COMMAND \"${CMAKE_COMMAND}\" -G \"${CMAKE_GENERATOR}\" -P \"${FIRE_POST_INSTALL_CMAKE_PATH}\" WORKING_DIRECTORY \$ENV{CMAKE_INSTALL_PREFIX})
      endif ()
    else()
      # set(ENV{CMAKE_INSTALL_PREFIX} \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}\")
      # set(ENV{CMAKE_INSTALL_LIBDIR} \${CMAKE_INSTALL_LIBDIR})
      # execute_process(COMMAND \"${CMAKE_COMMAND}\" -G \"${CMAKE_GENERATOR}\" -P \"${FIRE_POST_INSTALL_CMAKE_PATH}\"  WORKING_DIRECTORY \$ENV{CMAKE_INSTALL_PREFIX})
    endif()
  "
  COMPONENT LibraryComponent
  )

  SET (CPACK_PRE_BUILD_SCRIPT_PC_PATH ${CMAKE_CURRENT_BINARY_DIR}/cpack_pre_build_script_pc_${TARGET}.cmake)
  FILE (WRITE  ${CPACK_PRE_BUILD_SCRIPT_PC_PATH} "# Content of this file is overwriten at cpack install using CPACK_INSTALL_SCRIPT\n")
  LIST (APPEND CPACK_PRE_BUILD_SCRIPTS ${CPACK_PRE_BUILD_SCRIPT_PC_PATH})
  SET (CPACK_PRE_BUILD_SCRIPTS ${CPACK_PRE_BUILD_SCRIPTS} PARENT_SCOPE)
endfunction()

MACRO (MYPACKAGEPKGCONFIGEXPORT)
  IF (NOT ${PROJECT_NAME}_NO_CONFIGEXPORT)
    #
    # We depend on CMake exports
    #
    IF (NOT CMAKE_VERSION VERSION_LESS "3.27")
      MYPACKAGECMAKEEXPORT()
      auto_pc(${PROJECT_NAME})
      # Clean up install path
      install(CODE [[ file(REMOVE_RECURSE "${CMAKE_INSTALL_PREFIX}/_auto_pc") ]])
    ELSE ()
      MESSAGE (AUTHOR_WARNING "Pkgconfig export requires version >= 3.26")
    ENDIF ()
  ENDIF ()
ENDMACRO ()
