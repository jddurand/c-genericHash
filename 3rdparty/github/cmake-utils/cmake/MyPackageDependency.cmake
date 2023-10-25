MACRO (MYPACKAGEDEPENDENCY packageDepend packageDependSourceDir)
  #
  # Optional argument:
  # - TESTS  : Lookup test execitables
  # - LIBS   : Lookup current project's libraries, implies TESTS
  # - EXES   : Lookup executables
  # - LOCAL  : Source is local
  # - STATIC : Use current project's static library if any
  # - PRIVATE: Dependency is private
  #
  # Default is to lookup everything
  SET (_ALL TRUE)
  SET (_TESTS FALSE)
  SET (_LIBS FALSE)
  SET (_EXES FALSE)
  SET (_LOCAL FALSE)
  SET (_STATIC FALSE)
  SET (_PRIVATE FALSE)
  SET (_OBJECT FALSE)
  FOREACH (_var ${ARGN})
    IF (${_var} STREQUAL TESTS)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} test scope argument")
      ENDIF ()
      SET (_ALL FALSE)
      SET (_TESTS TRUE)
    ENDIF ()
    IF (${_var} STREQUAL LIBS)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} library scope argument, implies test")
      ENDIF ()
      SET (_ALL FALSE)
      SET (_LIBS TRUE)
      SET (_TESTS TRUE)
    ENDIF ()
    IF (${_var} STREQUAL EXES)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} executables scope argument")
      ENDIF ()
      SET (_ALL FALSE)
      SET (_EXES TRUE)
    ENDIF ()
    IF (${_var} STREQUAL LOCAL)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} local mode")
      ENDIF ()
      SET (_LOCAL TRUE)
    ENDIF ()
    IF (${_var} STREQUAL STATIC)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} static mode")
      ENDIF ()
      SET (_STATIC TRUE)
    ENDIF ()
    IF (${_var} STREQUAL PRIVATE)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} private dependency")
      ENDIF ()
      SET (_PRIVATE TRUE)
    ENDIF ()
    IF (${_var} STREQUAL OBJECT)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} object dependency")
      ENDIF ()
      SET (_OBJECT TRUE)
	  #
	  # When this is an OBJECT dependency, scope is necessarly private
	  #
	  SET (_PRIVATE TRUE)
    ENDIF ()
  ENDFOREACH ()
  IF (_ALL)
    SET (_TESTS TRUE)
    SET (_LIBS TRUE)
    SET (_EXES TRUE)
  ENDIF ()
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} dependency check with: ALL=${_ALL} TEST=${_TESTS} LIBS=${_LIBS} EXES=${_EXES} LOCAL=${_LOCAL} STATIC=${_STATIC} PRIVATE=${_PRIVATE} OBJECT=${_OBJECT}")
  ENDIF ()
  #
  # Set dependency scope: PUBLIC or PRIVATE depending on _STATIC
  #
  IF (_PRIVATE)
    SET (_package_dependency_scope PRIVATE)
	#
	# We do not want to install config's export
	#
	SET (${packageDepend}_NO_CONFIGEXPORT TRUE)
  ELSE ()
    SET (_package_dependency_scope PUBLIC)
  ENDIF ()
  #
  # Check if inclusion was already done - via us or another mechanism... guessed with TARGET check
  #
  GET_PROPERTY(_packageDepend_set GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend} SET)
  IF (${_packageDepend_set})
    GET_PROPERTY(_packageDepend GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend})
  ELSE ()
    SET (_packageDepend "")
  ENDIF ()
  IF ((NOT ("${_packageDepend}" STREQUAL "")) OR (TARGET ${packageDepend}))
    IF (${_packageDepend_set})
      IF (${_packageDepend} STREQUAL "PENDING")
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} is already being processed")
        ENDIF ()
      ELSE ()
        IF (${_packageDepend} STREQUAL "DONE")
          GET_PROPERTY(_packageDepend_version GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend}_VERSION)
          IF (MYPACKAGE_DEBUG)
            MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} is already available, version ${_packageDepend_version}")
          ENDIF ()
        ELSE ()
          MESSAGE (FATAL_ERROR "[${PROJECT_NAME}-DEPEND-STATUS] ${packageDepend} state is ${_packageDepend}, should be DONE or PENDING")
        ENDIF ()
      ENDIF ()
    ELSE ()
      # MESSAGE (WARNING "[${PROJECT_NAME}-DEPEND-WARNING] Target ${packageDepend} already exist - use MyPackageDependency to avoid this warning")
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Setting property MYPACKAGE_DEPENDENCY_${packageDepend} to DONE")
      ENDIF ()
      SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend} "DONE")
    ENDIF ()
  ELSE ()
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} is not yet available")
      MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Setting property MYPACKAGE_DEPENDENCY_${packageDepend} to PENDING")
    ENDIF ()
    SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend} "PENDING")
    #
    # ===================================================
    # Do the dependency: ADD_SUBDIRECTORY or FIND_PACKAGE
    # ===================================================
    #
    STRING (TOUPPER ${packageDepend} _PACKAGEDEPEND)
    IF (_LOCAL)
      GET_FILENAME_COMPONENT(packageDependSourceDirAbsolute ${packageDependSourceDir} ABSOLUTE)
	  IF (_OBJECT OR (_TESTS AND NOT (_LIBS OR _EXES)))
	    #
		# If caller calls for an object dependency or for a test-only dependency there is no install to do
		#
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding subdirectory ${packageDependSourceDirAbsolute} EXCLUDE_FROM_ALL")
	    ENDIF ()
        ADD_SUBDIRECTORY(${packageDependSourceDirAbsolute} EXCLUDE_FROM_ALL)
	  ELSE ()
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding subdirectory ${packageDependSourceDirAbsolute}")
	    ENDIF ()
        ADD_SUBDIRECTORY(${packageDependSourceDirAbsolute})
	  ENDIF ()
	  #
	  # We want to get the dependency version in our scope
	  #
	  GET_DIRECTORY_PROPERTY(${packageDepend}_VERSION DIRECTORY ${packageDependSourceDirAbsolute} DEFINITION PROJECT_VERSION)
    ELSE ()
      MESSAGE(STATUS "[${PROJECT_NAME}-DEPEND-STATUS] Looking for ${packageDepend}")
      FIND_PACKAGE (${packageDepend})
      IF (NOT ${_PACKAGEDEPEND}_FOUND)
        MESSAGE (FATAL_ERROR "[${PROJECT_NAME}-DEPEND-STATUS] Find ${packageDepend} failed")
      ENDIF ()
    ENDIF ()
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Setting property MYPACKAGE_DEPENDENCY_${packageDepend}_VERSION to ${${packageDepend}_VERSION}")
    ENDIF ()
    SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend}_VERSION "${${packageDepend}_VERSION}")
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Setting property MYPACKAGE_DEPENDENCY_${packageDepend} to DONE")
    ENDIF ()
    SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend} "DONE")
  ENDIF ()
  #
  # Gather current project's target candidates
  #
  SET (_test_candidates ${${PROJECT_NAME}_TEST_EXECUTABLE})
  SET (_lib_candidates ${PROJECT_NAME} ${PROJECT_NAME}_static ${PROJECT_NAME}_objs ${PROJECT_NAME}_static_objs)
  SET (_exe_candidates  ${${PROJECT_NAME}_EXECUTABLE})
  SET (_candidates)
  IF (_TESTS)
    LIST (APPEND _candidates ${_test_candidates})
  ENDIF ()
  IF (_LIBS)
    LIST (APPEND _candidates ${_lib_candidates})
  ENDIF ()
  IF (_EXES)
    LIST (APPEND _candidates ${_exe_candidates})
  ENDIF ()
  #
  # Do packageDepend provide library ?
  #
  SET (realPackageDepend ${packageDepend})
  IF (_STATIC AND TARGET ${packageDepend}_static)
    IF (_OBJECT)
      SET (realPackageDepend ${packageDepend}_static_objs)
    ELSE ()
      SET (realPackageDepend ${packageDepend}_static)
    ENDIF ()
  ELSEIF (_OBJECT AND TARGET ${packageDepend})
    SET (realPackageDepend ${packageDepend}_objs)
  ENDIF ()
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${packageDepend} resolved to ${realPackageDepend}")
  ENDIF ()
  #
  # Loop on current project's target candidates
  #
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Target candidates: ${_candidates}")
  ENDIF ()
  FOREACH (_target ${_candidates})
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Inspecting target candidate ${_target}")
    ENDIF ()
    IF (TARGET ${_target})
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Inspecting target candidate ${_target} exists")
      ENDIF ()
      IF (TARGET ${realPackageDepend})
		GET_TARGET_PROPERTY(realPackageDepend_type ${realPackageDepend} TYPE)
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding ${_package_dependency_scope} dependency on ${realPackageDepend}, of type ${realPackageDepend_type}, for target ${_target}")
        ENDIF ()
        IF ((realPackageDepend_type STREQUAL STATIC_LIBRARY) OR (realPackageDepend_type STREQUAL SHARED_LIBRARY))
		  #
		  # Dependency is on a true library: export target will have to produce a dependency as well
		  #
          TARGET_LINK_LIBRARIES(${_target} ${_package_dependency_scope} ${realPackageDepend})
		  IF (NOT ${realPackageDepend} IN_LIST ${PROJECT_NAME}_public_dependencies)
            IF (MYPACKAGE_DEBUG)
              MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding ${realPackageDepend} import dependency for target ${_target}")
            ENDIF ()
		    LIST(APPEND ${PROJECT_NAME}_public_dependencies ${realPackageDepend})
		  ENDIF ()
	      IF (NOT ${packageDepend} IN_LIST ${PROJECT_NAME}_build_dependencies)
		    IF (MYPACKAGE_DEBUG)
              MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding ${packageDepend} build dependency for project ${PROJECT_NAME}")
            ENDIF ()
            LIST(APPEND ${PROJECT_NAME}_build_dependencies ${packageDepend})
          ENDIF ()
		ELSE ()
          TARGET_LINK_LIBRARIES(${_target} ${_package_dependency_scope} $<${build_local_interface}:${realPackageDepend}>)
		ENDIF ()
        IF (_TESTS AND (realPackageDepend_type STREQUAL STATIC_LIBRARY) OR (realPackageDepend_type STREQUAL SHARED_LIBRARY))
          #
          # A bit painful but the target locations are not known at this time.
          # We remember all library targets for later use in the check generation command.
          #
          GET_PROPERTY(_targets_for_test_set GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST)
          IF (NOT _targets_for_test_set)
            SET (_targets_for_test ${realPackageDepend})
            IF (MYPACKAGE_DEBUG)
              MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Initialized MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST with ${realPackageDepend}")
            ENDIF ()
            SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST ${_targets_for_test})
          ELSE ()
            LIST (FIND _targets_for_test ${realPackageDepend} _targets_for_test_found)
            IF (${_targets_for_test_found} EQUAL -1)
              LIST (APPEND _targets_for_test ${realPackageDepend})
              IF (MYPACKAGE_DEBUG)
                MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Appended MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST with ${realPackageDepend}")
              ENDIF ()
              SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST ${_targets_for_test})
            ENDIF ()
           ENDIF ()
        ENDIF ()
      ELSE ()
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${realPackageDepend} does not produce a library")
        ENDIF ()
        #
        # Bad luck, this target does not generate a library. We use global properties.
        #
        GET_PROPERTY(_packageDepend_include_dirs_set GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend}_INCLUDE_DIRS SET)
        IF (_packageDepend_include_dirs_set)
          GET_PROPERTY(_packageDepend_include_dirs GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend}_INCLUDE_DIRS)
        ELSE ()
          SET (_packageDepend_include_dirs)
          FOREACH (_include_dir ${packageDependSourceDir}/output/include ${packageDependSourceDir}/include)
            GET_FILENAME_COMPONENT(_absolute_include_dir ${_include_directory} ABSOLUTE)
            LIST (APPEND _packageDepend_include_dirs ${_absolute_include_dir})
          ENDFOREACH ()
		  
          SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend}_INCLUDE_DIRS ${_packageDepend_include_dirs})
          IF (MYPACKAGE_DEBUG)
            MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] MYPACKAGE_DEPENDENCY_${packageDepend}_INCLUDE_DIRS initialized to ${_packageDepend_include_dirs}")
            MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Use MyPackageStart to avoid this fallback")
          ENDIF ()
        ENDIF ()
        #
        # Apply ${_packageDepend_include_dirs}, eventually update our _INCLUDE_DIRS
        #
        GET_PROPERTY(_include_dirs GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_INCLUDE_DIRS)
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${PROJECT_NAME} current include dirs list is ${_include_dirs}")
        ENDIF ()
        FOREACH (_packageDepend_include_dir ${_packageDepend_include_dirs})
		  IF (${_packageDepend_include_dir} IN_LIST _include_dirs)
            IF (MYPACKAGE_DEBUG)
              MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] ${_packageDepend_include_dir} is already in ${PROJECT_NAME} include dirs")
            ENDIF ()
		  ELSE ()
            IF (MYPACKAGE_DEBUG)
              MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding ${_packageDepend_include_dir} in ${PROJECT_NAME} include dirs")
            ENDIF ()
			LIST (APPEND _include_dirs ${_packageDepend_include_dir})
            SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_INCLUDE_DIRS ${_include_dirs})
		  ENDIF ()
          IF (MYPACKAGE_DEBUG)
            MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Adding ${_package_dependency_scope} include dependency on ${_packageDepend_include_dir} for target ${_target}")
          ENDIF ()
          TARGET_INCLUDE_DIRECTORIES(${_target} ${_package_dependency_scope} $<${build_local_interface}:${_packageDepend_include_dir}>)
        ENDFOREACH ()
        # TARGET_INCLUDE_DIRECTORIES(${_target} ${_package_dependency_scope} $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
      ENDIF ()
    ELSE ()
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] No target ${_target}")
      ENDIF ()
    ENDIF ()
  ENDFOREACH ()
  #
  # Test path management
  #
  GET_PROPERTY(_test_path_set GLOBAL PROPERTY MYPACKAGE_TEST_PATH SET)
  IF (${_test_path_set})
    GET_PROPERTY(_test_path GLOBAL PROPERTY MYPACKAGE_TEST_PATH)
  ELSE ()
    SET (_test_path $ENV{PATH})
    IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
      STRING(REGEX REPLACE "/" "\\\\"  _test_path "${_test_path}")
    ELSE ()
      STRING(REGEX REPLACE " " "\\\\ "  _test_path "${_test_path}")
    ENDIF ()
    IF (MYPACKAGE_DEBUG)
      MESSAGE(STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Initializing TEST_PATH with PATH")
    ENDIF ()
    SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_TEST_PATH ${_test_path})
  ENDIF ()

  GET_PROPERTY(_dependLibraryRuntimeDirectories GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${packageDepend}_LIBRARIES)
  #
  # On Windows we want to make sure it contains a bin in the last component
  #
  SET (_have_bin FALSE)
  IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
    FOREACH (_dir ${_dependLibraryRuntimeDirectories})
      GET_FILENAME_COMPONENT(_lastdir ${_dir} NAME)
      STRING (TOUPPER ${_lastdir} _lastdir)
      IF ("${_lastdir}" STREQUAL "BIN")
        SET (_have_bin TRUE)
        BREAK ()
      ENDIF ()
    ENDFOREACH ()
    IF (NOT _have_bin)
      SET (_dependLibraryRuntimeDirectoriesOld ${_dependLibraryRuntimeDirectories})
      FOREACH (_dir ${_dependLibraryRuntimeDirectoriesOld})
        GET_FILENAME_COMPONENT(_updir ${_dir} DIRECTORY)
        SET (_bindir "${_updir}/bin")
        IF (EXISTS "${_bindir}")
          LIST (APPEND _dependLibraryRuntimeDirectories "${_bindir}")
        ENDIF ()
      ENDFOREACH ()
    ENDIF ()
  ENDIF ()
  IF (NOT ("${_dependLibraryRuntimeDirectories}" STREQUAL ""))
    IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
      SET (SEP "\\;")
    ELSE ()
      SET (SEP ":")
    ENDIF ()
    FOREACH (_dir ${_dependLibraryRuntimeDirectories})
      IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
        STRING(REGEX REPLACE "/" "\\\\"  _dir "${_dir}")
      ELSE ()
        STRING(REGEX REPLACE " " "\\\\ "  _dir "${_dir}")
      ENDIF ()
      SET (_test_path "${_dir}${SEP}${_test_path}")
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-DEPEND-DEBUG] Prepended ${_dir} to TEST_PATH")
      ENDIF ()
      SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_TEST_PATH ${_test_path})
    ENDFOREACH ()
  ENDIF ()
  SET (TEST_PATH ${_test_path} CACHE INTERNAL "Test Path" FORCE)
ENDMACRO()
