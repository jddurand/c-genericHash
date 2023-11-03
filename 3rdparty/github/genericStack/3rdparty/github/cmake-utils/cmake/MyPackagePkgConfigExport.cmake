cmake_minimum_required(VERSION 3.15 FATAL_ERROR) # For list(PREPEND ...)
#
# Based on https://stackoverflow.com/questions/44292462/how-to-auto-generate-pkgconfig-files-from-cmake-targets
#
function(auto_pc TARGET)
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-PKGCONFIG-DEBUG] Running on target ${TARGET}")
  ENDIF ()

  file(CONFIGURE OUTPUT "pc.${TARGET}/CMakeLists.txt"
       CONTENT [[
cmake_minimum_required(VERSION 3.16)
project(pc_@TARGET@)

message(STATUS "[pc.@TARGET@/build] Starting")

message(STATUS "[pc.@TARGET@/build] Initializing CMAKE_PREFIX_PATH with: $ENV{CMAKE_MODULE_ROOT_PATH_ENV}/@TARGET@")
set(CMAKE_PREFIX_PATH "$ENV{CMAKE_MODULE_ROOT_PATH_ENV}/@TARGET@")

message(STATUS "[pc.@TARGET@/build] Requiring @TARGET@")
find_package(@TARGET@ REQUIRED)

#
# It is important to do static before shared, because shared will reuse static properties
#
foreach(_target_type iface static shared)
  set(_target @TARGET@::@TARGET@_${_target_type})
  if(TARGET ${_target})
    get_target_property(_interface_link_libraries ${_target} INTERFACE_LINK_LIBRARIES)
    message(STATUS "[pc.@TARGET@/build] ${_target} INTERFACE_LINK_LIBRARIES: ${_interface_link_libraries}")
    set(_computed_requires)
    foreach(_interface_link_library ${_interface_link_libraries})
      if(TARGET ${_interface_link_library})
        string(REGEX REPLACE ".*::" "" _computed_require ${_interface_link_library})
        list(APPEND _computed_requires ${_computed_require})
      endif()
    endforeach()
    #
    # iface produce no output file
    # static produces @TARGET@_static
    # shared produces @TARGET@
    #
    set_target_properties(${_target} PROPERTIES PC_NAME "@TARGET@_${_target_type}")
    if(${_target_type} STREQUAL "iface")
      set_target_properties(${_target} PROPERTIES PC_DESCRIPTION "@TARGET@ headers")
    elseif(${_target_type} STREQUAL "shared")
      set_target_properties(${_target} PROPERTIES PC_DESCRIPTION "@TARGET@ dynamic library")
    elseif(${_target_type} STREQUAL "static")
      set_target_properties(${_target} PROPERTIES PC_DESCRIPTION "@TARGET@ static library")
    else()
      message(FATAL_ERROR "Unsupported target type ${_target_type}")
    endif()
    if (_computed_requires)
      list(JOIN _computed_requires "," _pc_requires)
      set_target_properties(${_target} PROPERTIES PC_REQUIRES "${_pc_requires}")
    endif()
    if(_target_type STREQUAL "shared")
      #
      # By definition the "static" target should already exist
      #
      set(_target_static @TARGET@::@TARGET@_static)
      if(TARGET ${_target_static})
        #
        # Requires.private
        #
        get_target_property(_pc_requires_private ${_target_static} PC_REQUIRES)
        if(_pc_requires_private)
          set_target_properties(${_target} PROPERTIES PC_REQUIRES_PRIVATE "${_pc_requires_private}")
        endif()
        #
        # Cflags.private
        #
        get_target_property(_pc_interface_compile_definitions_private ${_target_static} INTERFACE_COMPILE_DEFINITIONS)
        if(_pc_interface_compile_definitions_private)
          set_target_properties(${_target} PROPERTIES PC_INTERFACE_COMPILE_DEFINITIONS_PRIVATE "${_pc_interface_compile_definitions_private}")
        endif()
        #
        # Libs.private
        #
        get_target_property(_pc_libs_private ${_target_static} PC_LIBS)
        if(_pc_libs_private)
          set_target_properties(${_target} PROPERTIES PC_LIBS_PRIVATE "${_pc_libs_private}")
        endif()
      endif()
    endif()
    set_target_properties(${_target} PROPERTIES PC_VERSION "${@TARGET@_VERSION}")
    set_target_properties(${_target} PROPERTIES PC_VERSION_MAJOR "${@TARGET@_VERSION_MAJOR}")

    get_target_property(_location ${_target} LOCATION)
    if(_location)
      cmake_path(GET _location FILENAME _filename)
      if(_target_type STREQUAL "shared")
        get_filename_component(_filename_we ${_filename} NAME_WE)
        if(NOT ("x${CMAKE_SHARED_LIBRARY_PREFIX}" STREQUAL "x"))
          string(REGEX REPLACE "^${CMAKE_SHARED_LIBRARY_PREFIX}" "" _filename_we ${_filename_we})
        endif()
        set_target_properties(${_target} PROPERTIES PC_LIBS "-L\${libdir} -l${_filename_we}")
      elseif(_target_type STREQUAL "static")
        set_target_properties(${_target} PROPERTIES PC_LIBS "\${libdir}/${_filename}")
      endif()
    endif()
    LIST(APPEND _target_computed_dependencies ${_target_filename_we})
  endif()
endforeach()

foreach(_target_type iface static shared)
  set(_target @TARGET@::@TARGET@_${_target_type})
  if(TARGET ${_target})
    set(_file @TARGET@_${_target_type}.pc)
    message(STATUS "[pc.@TARGET@/build] Generating ${_file}")
    file(GENERATE OUTPUT ${_file}
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

Name: $<TARGET_PROPERTY:PC_NAME>
Description: $<TARGET_PROPERTY:PC_DESCRIPTION>
Version: $<TARGET_PROPERTY:PC_VERSION>
Requires: $<IF:$<BOOL:$<TARGET_PROPERTY:PC_REQUIRES>>,$<TARGET_PROPERTY:PC_REQUIRES>,>
Requires.private: $<IF:$<BOOL:$<TARGET_PROPERTY:PC_REQUIRES_PRIVATE>>,$<TARGET_PROPERTY:PC_REQUIRES_PRIVATE>,>
Cflags: -I${includedir} $<IF:$<BOOL:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>>,-D$<JOIN:$<TARGET_PROPERTY:INTERFACE_COMPILE_DEFINITIONS>, -D>,>
Cflags.private: $<IF:$<BOOL:$<TARGET_PROPERTY:PC_INTERFACE_COMPILE_DEFINITIONS_PRIVATE>>,-I${includedir} -D$<JOIN:$<TARGET_PROPERTY:PC_INTERFACE_COMPILE_DEFINITIONS_PRIVATE>, -D>,>
Libs: $<IF:$<BOOL:$<TARGET_PROPERTY:PC_LIBS>>,$<TARGET_PROPERTY:PC_LIBS>,>
Libs.private: $<IF:$<BOOL:$<TARGET_PROPERTY:PC_LIBS_PRIVATE>>,$<TARGET_PROPERTY:PC_LIBS_PRIVATE>,>
]=] TARGET ${_target} NEWLINE_STYLE LF)

  endif()
endforeach()
]] @ONLY NEWLINE_STYLE LF)

  file(CONFIGURE OUTPUT "pc.${TARGET}/post-install.cmake"
    CONTENT [[
set(proj "@CMAKE_CURRENT_BINARY_DIR@/pc.@TARGET@")
message(STATUS "[pc.@TARGET@/post-install.cmake] Building in ${proj}/build")
execute_process(COMMAND "@CMAKE_COMMAND@" -G "@CMAKE_GENERATOR@" -S "${proj}" -B "${proj}/build")
]] @ONLY NEWLINE_STYLE LF)

  SET (FIRE_POST_INSTALL_CMAKE_PATH ${CMAKE_CURRENT_BINARY_DIR}/fire_post_install.cmake)
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-PKGCONFIG-DEBUG] Generating ${FIRE_POST_INSTALL_CMAKE_PATH}")
  ENDIF ()
  FILE(WRITE  ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"[fire_post_install.cmake] \\\$ENV{DESTDIR}: \\\"\$ENV{DESTDIR}\\\"\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_INSTALL_PREFIX \"\$ENV{CMAKE_INSTALL_PREFIX_ENV}\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"[fire_post_install.cmake] CMAKE_INSTALL_PREFIX: \\\"\${CMAKE_INSTALL_PREFIX}\\\"\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_INSTALL_LIBDIR \"\$ENV{CMAKE_INSTALL_LIBDIR_ENV}\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"[fire_post_install.cmake] CMAKE_INSTALL_LIBDIR: \\\"\${CMAKE_INSTALL_LIBDIR}\\\"\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "set(CMAKE_MODULE_ROOT_PATH \"\$ENV{CMAKE_MODULE_ROOT_PATH_ENV}\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"[fire_post_install.cmake] CMAKE_MODULE_ROOT_PATH: \\\"\${CMAKE_MODULE_ROOT_PATH}\\\"\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "message(STATUS \"[fire_post_install.cmake] Including ${CMAKE_CURRENT_BINARY_DIR}/pc.${PROJECT_NAME}/post-install.cmake\")\n")
  FILE(APPEND ${FIRE_POST_INSTALL_CMAKE_PATH} "include(${CMAKE_CURRENT_BINARY_DIR}/pc.${PROJECT_NAME}/post-install.cmake)\n")
  #
  # At each install we decrement the number of remaining post installs, and fire all of them when the number is 0
  # We CANNOT use CMAKE_INSTALL_PREFIX variable contrary to what is posted almost everywhere on the net: CPack will
  # will have a CMAKE_INSTALL_PREFIX different, the real and only way to know exactly where we install things is to
  # set the current working directory to ${DESTDIR}${CMAKE_INSTALL_PREFIX}, and use WORKING_DIRECTORY as the full install prefix dir.
  #
  INSTALL(CODE "
    set(CPACK_IS_RUNNING \$ENV{CPACK_IS_RUNNING})
    #
    # We do not want to run this when it is CPack
    #
    if (NOT CPACK_IS_RUNNING)
      # We need to re-evaluate GNUInstallDirs to get CMAKE_INSTALL_LIBDIR
      set(CMAKE_SYSTEM_NAME \"${CMAKE_SYSTEM_NAME}\")
      set(CMAKE_SIZEOF_VOID_P \"${CMAKE_SIZEOF_VOID_P}\")
      include(GNUInstallDirs)
      message(STATUS \"\\\$ENV{DESTDIR} is: \\\"\$ENV{DESTDIR}\\\"\")
      message(STATUS \"CMAKE_INSTALL_PREFIX is: \\\"\${CMAKE_INSTALL_PREFIX}\\\"\")
      message(STATUS \"CMAKE_INSTALL_LIBDIR is: \\\"\${CMAKE_INSTALL_LIBDIR}\\\"\")
      set(ENV{CMAKE_INSTALL_PREFIX_ENV} \"\${CMAKE_INSTALL_PREFIX}\") # Variable may be empty
      set(ENV{CMAKE_INSTALL_LIBDIR_ENV} \"\${CMAKE_INSTALL_LIBDIR}\") # Variable may be empty
      set(ENV{CMAKE_MODULE_ROOT_PATH_ENV} \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/\${CMAKE_INSTALL_LIBDIR}/cmake\")
      execute_process(COMMAND \"${CMAKE_COMMAND}\" -G \"${CMAKE_GENERATOR}\" -P \"${FIRE_POST_INSTALL_CMAKE_PATH}\" WORKING_DIRECTORY \${CMAKE_INSTALL_PREFIX})
    endif()
  "
  COMPONENT LibraryComponent
  )
  #
  # Generate a file that will be overwriten by the post-install scripts
  #
  FOREACH (_target_type iface static shared)
    IF (TARGET ${TARGET}_${_target_type})
      SET (FIRE_POST_INSTALL_PKGCONFIG_PATH ${CMAKE_CURRENT_BINARY_DIR}/pc.${TARGET}/build/${TARGET}_${_target_type}.pc)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-PKGCONFIG-DEBUG] Generating dummy ${FIRE_POST_INSTALL_PKGCONFIG_PATH}")
      ENDIF ()
      FILE (WRITE ${FIRE_POST_INSTALL_PKGCONFIG_PATH} "# Content of this file is overwriten during install or package phases")
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-PKGCONFIG-DEBUG] INSTALL (FILES ${FIRE_POST_INSTALL_PKGCONFIG_PATH} DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig COMPONENT LibraryComponent)")
      ENDIF ()
      INSTALL (FILES ${FIRE_POST_INSTALL_PKGCONFIG_PATH} DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig COMPONENT LibraryComponent)
    ENDIF ()
  ENDFOREACH ()

  SET (CPACK_PRE_BUILD_SCRIPT_PC_PATH ${CMAKE_CURRENT_BINARY_DIR}/cpack_pre_build_script_pc_${TARGET}.cmake)
  FILE (WRITE  ${CPACK_PRE_BUILD_SCRIPT_PC_PATH} "# Content of this file is overwriten during package phase")
  LIST (APPEND CPACK_PRE_BUILD_SCRIPTS ${CPACK_PRE_BUILD_SCRIPT_PC_PATH})
  SET (CPACK_PRE_BUILD_SCRIPTS ${CPACK_PRE_BUILD_SCRIPTS} PARENT_SCOPE)
endfunction()

MACRO (MYPACKAGEPKGCONFIGEXPORT)
  MYPACKAGECMAKEEXPORT()
  auto_pc(${PROJECT_NAME})
ENDMACRO ()
