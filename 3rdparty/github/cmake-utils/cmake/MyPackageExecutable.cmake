MACRO (MYPACKAGEEXECUTABLE name)
  IF (MYPACKAGE_DEBUG)
    FOREACH (_source ${ARGN})
      MESSAGE (STATUS "[${PROJECT_NAME}-EXECUTABLE-DEBUG] Source: ${_source}")
    ENDFOREACH ()
  ENDIF ()
  #
  # User-friendly name for an executable do not include the "_shared" word. We
  # produce at most two executables:
  # ${name} if there is a shared library or an iface interface
  # ${name}_static if there is a static library
  #
  SET (_candidates)
  IF ((TARGET ${PROJECT_NAME}_shared) OR (TARGET ${PROJECT_NAME}_iface))
    LIST(APPEND _candidates ${name})
  ENDIF ()
  IF (TARGET ${PROJECT_NAME}_static)
    LIST(APPEND _candidates ${name}_static)
  ENDIF ()

  FOREACH (_target ${_candidates})
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-EXECUTABLE-DEBUG] Adding ${_target}")
    ENDIF ()
    LIST (APPEND ${PROJECT_NAME}_EXECUTABLE ${_target})
    ADD_EXECUTABLE (${_target} ${ARGN})
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-EXECUTABLE-DEBUG] SET_TARGET_PROPERTIES (${_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH})")
    ENDIF ()
    SET_TARGET_PROPERTIES (${_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH})
    INSTALL (
      TARGETS ${_target}
      EXPORT ${PROJECT_NAME}-targets
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT ApplicationComponent
    )
    SET (${PROJECT_NAME}_HAVE_APPLICATIONCOMPONENT TRUE CACHE INTERNAL "Have ApplicationComponent" FORCE)
 
    IF (${_target} STREQUAL ${name})
      IF (TARGET ${PROJECT_NAME}_shared)
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-EXECUTABLE-DEBUG] TARGET_LINK_LIBRARIES(${_target} PUBLIC ${PROJECT_NAME}_shared)")
        ENDIF ()
        TARGET_LINK_LIBRARIES(${_target} PUBLIC ${PROJECT_NAME}_shared)
      ELSE ()
        IF (MYPACKAGE_DEBUG)
          MESSAGE (STATUS "[${PROJECT_NAME}-EXECUTABLE-DEBUG] TARGET_LINK_LIBRARIES(${_target} PUBLIC ${PROJECT_NAME}_iface)")
        ENDIF ()
        TARGET_LINK_LIBRARIES(${_target} PUBLIC ${PROJECT_NAME}_iface)
      ENDIF ()
    ENDIF ()

    IF (${_target} STREQUAL ${name}_static)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-EXECUTABLE-DEBUG] TARGET_LINK_LIBRARIES(${_target} PUBLIC ${PROJECT_NAME}_static)")
      ENDIF ()
      TARGET_LINK_LIBRARIES(${_target} PUBLIC ${PROJECT_NAME}_static)
    ENDIF ()

  ENDFOREACH ()
ENDMACRO()
