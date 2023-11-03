MACRO (MYPACKAGECMAKEEXPORT)
  IF (NOT MYPACKAGECMAKEEXPORT_${PROJECT_NAME}_DONE)
    #
    # Because internally MYPACKAGEPKGCONFIGEXPORT() also calls MYPACKAGECMAKEEXPORT
    #
    SET (MYPACKAGECMAKEEXPORT_${PROJECT_NAME}_DONE TRUE)

    SET (_export_targets ${PROJECT_NAME}-targets)
    SET (_namespace ${PROJECT_NAME}::)
    IF (MYPACKAGE_DEBUG)
      MESSAGE(STATUS "[${PROJECT_NAME}-CMAKEEXPORT-DEBUG] Exporting ${_export_targets}")
    ENDIF ()
    SET (TARGET_CMAKE_IN ${CMAKE_CURRENT_BINARY_DIR}/${_export_targets}.cmake.in)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-CMAKEEXPORT-DEBUG] Generating ${TARGET_CMAKE_IN}")
    ENDIF ()
    SET (_target_cmake_in [[
@PACKAGE_INIT@

]])
    #
    # Explicit public dependencies
    #
    IF (${PROJECT_NAME}_package_dependencies)
      STRING (APPEND _target_cmake_in "include(CMakeFindDependencyMacro)")
      STRING (APPEND _target_cmake_in [[

]])
      FOREACH (_package_dependency ${${PROJECT_NAME}_package_dependencies})
        GET_PROPERTY(_package_dependency_version GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${_package_dependency}_VERSION)
        GET_PROPERTY(_package_dependency_version_major GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${_package_dependency}_VERSION_MAJOR)
        GET_PROPERTY(_package_dependency_version_minor GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${_package_dependency}_VERSION_MINOR)
        STRING (APPEND _target_cmake_in "find_dependency(${_package_dependency} ${_package_dependency_version} REQUIRED PATHS \${CMAKE_CURRENT_LIST_DIR}/../${_package_dependency})")
        STRING (APPEND _target_cmake_in [[

]])
      ENDFOREACH ()
    ENDIF ()
    STRING (APPEND _target_cmake_in [[

]])
    STRING (APPEND _target_cmake_in "include(\"\${CMAKE_CURRENT_LIST_DIR}/${_export_targets}.cmake\"\)")
    STRING (APPEND _target_cmake_in [[

]])
    FILE (WRITE ${TARGET_CMAKE_IN} ${_target_cmake_in})
    INSTALL (EXPORT ${_export_targets}
      NAMESPACE ${_namespace}
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
      COMPONENT LibraryComponent)
    INCLUDE (CMakePackageConfigHelpers)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-CMAKEEXPORT-DEBUG] Generating ${PROJECT_NAME}Config.cmake")
    ENDIF ()
    CONFIGURE_PACKAGE_CONFIG_FILE(${TARGET_CMAKE_IN}
      ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
      INSTALL_DESTINATION lib/cmake/${PROJECT_NAME}
      NO_SET_AND_CHECK_MACRO
      NO_CHECK_REQUIRED_COMPONENTS_MACRO
    )
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-CMAKEEXPORT-DEBUG] Generating ${PROJECT_NAME}ConfigVersion.cmake")
    ENDIF ()
    WRITE_BASIC_PACKAGE_VERSION_FILE (
      ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
      VERSION ${PROJECT_VERSION}
      COMPATIBILITY SameMajorVersion
    )
    INSTALL (FILES
      ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
      COMPONENT LibraryComponent
    )
    FILE (REMOVE ${TARGET_CMAKE_IN} ${_target_cmake_in})
  ENDIF ()
ENDMACRO()
