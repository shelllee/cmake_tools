
#######################################################################################################
#  macro for linking libraries that come from Findxxxx commands, so there is a variable that contains the
#  full path of the library name. in order to differentiate release and debug, this macro get the
#  NAME of the variables, so the macro gets as arguments the target name and the following list of parameters
#  is intended as a list of variable names each one containing  the path of the libraries to link to
#  The existence of a variable name with _DEBUG appended is tested and, in case it' s value is used
#  for linking to when in debug mode
#  the content of this library for linking when in debugging
#######################################################################################################

# VALID_BUILDER_VERSION: used for replacing CMAKE_VERSION (available in v2.6.3 RC9) and VERSION_GREATER/VERSION_LESS (available in 2.6.2 RC4).
# This can be replaced by "IF(${CMAKE_VERSION} VERSION_LESS "x.y.z")" from 2.6.4.
SET(VALID_BUILDER_VERSION OFF)
MACRO(BUILDER_VERSION_GREATER MAJOR_VER MINOR_VER PATCH_VER)
	SET(VALID_BUILDER_VERSION OFF)
	IF(CMAKE_MAJOR_VERSION GREATER ${MAJOR_VER})
		SET(VALID_BUILDER_VERSION ON)
	ELSEIF(CMAKE_MAJOR_VERSION EQUAL ${MAJOR_VER})
		IF(CMAKE_MINOR_VERSION GREATER ${MINOR_VER})
		SET(VALID_BUILDER_VERSION ON)
		ELSEIF(CMAKE_MINOR_VERSION EQUAL ${MINOR_VER})
			IF(CMAKE_PATCH_VERSION GREATER ${PATCH_VER})
				SET(VALID_BUILDER_VERSION ON)
			ENDIF(CMAKE_PATCH_VERSION GREATER ${PATCH_VER})
		ENDIF()
	ENDIF()
ENDMACRO(BUILDER_VERSION_GREATER MAJOR_VER MINOR_VER PATCH_VER)

MACRO(LINK_INTERNAL TRGTNAME)
	TARGET_LINK_LIBRARIES(${TRGTNAME} ${ARGN})
ENDMACRO(LINK_INTERNAL TRGTNAME)

MACRO(LINK_EXTERNAL TRGTNAME)
	FOREACH(LINKLIB ${ARGN})
		TARGET_LINK_LIBRARIES(${TRGTNAME} "${LINKLIB}" )
	ENDFOREACH(LINKLIB)
ENDMACRO(LINK_EXTERNAL TRGTNAME)


#######################################################################################################
#  macro for common setup of core libraries: it links OPENGL_LIBRARIES in undifferentiated mode
#######################################################################################################

MACRO(LINK_CORELIB_DEFAULT CORELIB_NAME)
	SET(ALL_GL_LIBRARIES ${OPENGL_gl_LIBRARY})

	LINK_EXTERNAL(${CORELIB_NAME} ${ALL_GL_LIBRARIES})
#	LINK_WITH_VARIABLES(${CORELIB_NAME} OPENTHREADS_LIBRARY)

ENDMACRO(LINK_CORELIB_DEFAULT CORELIB_NAME)


#######################################################################################################
#  macro for common setup of plugins, examples and applications it expect some variables to be set:
#  either within the local CMakeLists or higher in hierarchy
#  TARGET_NAME is the name of the folder and of the actually .exe or .so or .dll
#  TARGET_TARGETNAME  is the name of the target , this get buit out of a prefix, if present and TARGET_TARGETNAME
#  TARGET_SRC  are the sources of the target
#  TARGET_H are the eventual headers of the target
#  TARGET_LIBRARIES are the libraries to link to that are internal to the project and have d suffix for debug
#  TARGET_EXTERNAL_LIBRARIES are external libraries and are not differentiated with d suffix
#  TARGET_LABEL is the label IDE should show up for targets
##########################################################################################################

MACRO(SETUP_LINK_LIBRARIES)
######################################################################
#
# This set up the libraries to link to, it assumes there are two variable: one common for a group of examples or plugins
# kept in the variable TARGET_COMMON_LIBRARIES and an example or plugin specific kept in TARGET_ADDED_LIBRARIES
# they are combined in a single list checked for unicity
# the suffix ${CMAKE_DEBUG_POSTFIX} is used for differentiating optimized and debug
#
# a second variable TARGET_EXTERNAL_LIBRARIES hold the list of  libraries not differentiated between debug and optimized
##################################################################################
	SET(TARGET_LIBRARIES ${TARGET_COMMON_LIBRARIES})

	FOREACH(LINKLIB ${TARGET_ADDED_LIBRARIES})
		SET(TO_INSERT TRUE)
		FOREACH (value ${TARGET_COMMON_LIBRARIES})
			IF (${value} STREQUAL ${LINKLIB})
			      SET(TO_INSERT FALSE)
			ENDIF (${value} STREQUAL ${LINKLIB})
			ENDFOREACH (value ${TARGET_COMMON_LIBRARIES})
		IF(TO_INSERT)
			LIST(APPEND TARGET_LIBRARIES ${LINKLIB})
		ENDIF(TO_INSERT)
	ENDFOREACH(LINKLIB)

	#SET(ALL_GL_LIBRARIES ${OPENGL_LIBRARIES})
	SET(ALL_GL_LIBRARIES ${OPENGL_gl_LIBRARY})
#	IF (OSG_GLES1_AVAILABLE OR OSG_GLES2_AVAILABLE)
#		SET(ALL_GL_LIBRARIES ${ALL_GL_LIBRARIES} ${OPENGL_egl_LIBRARY})
#	ENDIF()

	FOREACH(LINKLIB ${TARGET_LIBRARIES})
		TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} optimized ${LINKLIB} debug "${LINKLIB}${CMAKE_DEBUG_POSTFIX}")
	ENDFOREACH(LINKLIB)
#	LINK_INTERNAL(${TARGET_TARGETNAME} ${TARGET_LIBRARIES})
#	FOREACH(LINKLIB ${TARGET_EXTERNAL_LIBRARIES})
#		TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} ${LINKLIB})
#	ENDFOREACH(LINKLIB)

	TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} ${TARGET_EXTERNAL_LIBRARIES})
	IF(TARGET_LIBRARIES_VARS)
		LINK_WITH_VARIABLES(${TARGET_TARGETNAME} ${TARGET_LIBRARIES_VARS})
	ENDIF(TARGET_LIBRARIES_VARS)

#	IF(MSVC AND OSG_MSVC_VERSIONED_DLL)
#		#when using full path name to specify linkage, it seems that already linked libs must be specified
#		LINK_EXTERNAL(${TARGET_TARGETNAME} ${ALL_GL_LIBRARIES})
#	ENDIF(MSVC AND OSG_MSVC_VERSIONED_DLL)

	LINK_EXTERNAL(${TARGET_TARGETNAME} ${ALL_GL_LIBRARIES})

ENDMACRO(SETUP_LINK_LIBRARIES)

############################################################################################
# this is the common set of command for all the plugins
#
# Sets the output directory property for CMake >= 2.6.0, giving an output path RELATIVE to default one
MACRO(SET_OUTPUT_DIR_PROPERTY_260 TARGET_TARGETNAME RELATIVE_OUTDIR)
	BUILDER_VERSION_GREATER(2 8 0)
	IF(NOT VALID_BUILDER_VERSION)
		# If CMake <= 2.8.0 (Testing CMAKE_VERSION is possible in >= 2.6.4)
        IF(MSVC_IDE)
		# Using the "prefix" hack
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PREFIX "../${RELATIVE_OUTDIR}/")
        ELSE(MSVC_IDE)
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PREFIX "${RELATIVE_OUTDIR}/")
        ENDIF(MSVC_IDE)
	ELSE(NOT VALID_BUILDER_VERSION)
		# Using the output directory properties

		# Global properties (All generators but VS & Xcode)
		FILE(TO_CMAKE_PATH TMPVAR "CMAKE_ARCHIVE_OUTPUT_DIRECTORY/${RELATIVE_OUTDIR}")
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${TMPVAR}")
		FILE(TO_CMAKE_PATH TMPVAR "CMAKE_RUNTIME_OUTPUT_DIRECTORY/${RELATIVE_OUTDIR}")
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${TMPVAR}")
		FILE(TO_CMAKE_PATH TMPVAR "CMAKE_LIBRARY_OUTPUT_DIRECTORY/${RELATIVE_OUTDIR}")
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${TMPVAR}")

		# Per-configuration property (VS, Xcode)
		FOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})        # For each configuration (Debug, Release, MinSizeRel... and/or anything the user chooses)
			STRING(TOUPPER "${CONF}" CONF)                # Go uppercase (DEBUG, RELEASE...)

			# We use "FILE(TO_CMAKE_PATH", to create nice looking paths
			FILE(TO_CMAKE_PATH "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
			SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "ARCHIVE_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
			FILE(TO_CMAKE_PATH "${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
			SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "RUNTIME_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
			FILE(TO_CMAKE_PATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
			SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
		ENDFOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})
	ENDIF(NOT VALID_BUILDER_VERSION)
ENDMACRO(SET_OUTPUT_DIR_PROPERTY_260 TARGET_TARGETNAME RELATIVE_OUTDIR)

#######################################################################################################
#  macro for common setup of libraries it expect some variables to be set:
#  either within the local CMakeLists or higher in hierarchy
#  LIB_NAME  is the name of the target library
#  TARGET_SRC  are the sources of the target
#  TARGET_H are the eventual headers of the target
#  TARGET_H_NO_MODULE_INSTALL are headers that belong to target but shouldn't get installed by the ModuleInstall script
#  TARGET_LIBRARIES are the libraries to link to that are internal to the project and have d suffix for debug
#  TARGET_EXTERNAL_LIBRARIES are external libraries and are not differentiated with d suffix
#  TARGET_LABEL is the label IDE should show up for targets
##########################################################################################################

MACRO(SETUP_LIBRARY LIB_NAME)
	IF(GLCORE_FOUND)
		INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
	ENDIF(GLCORE_FOUND)

	SET(TARGET_NAME ${LIB_NAME} )
	SET(TARGET_TARGETNAME ${LIB_NAME} )
	ADD_LIBRARY(${LIB_NAME}
		${${PROJECT_NAME}_USER_DEFINED_DYNAMIC_OR_STATIC}
		${TARGET_H}
		${TARGET_H_NO_MODULE_INSTALL}
		${TARGET_SRC}
	)

#	message( "${PROJECT_NAME}_USER_DEFINED_DYNAMIC_OR_STATIC: " ${${PROJECT_NAME}_USER_DEFINED_DYNAMIC_OR_STATIC} )

#	PROCESS_POST_BUILD()

	SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES FOLDER ${TARGET_DEFAULT_LABEL_PREFIX})

	IF(TARGET_LABEL)
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
	ENDIF(TARGET_LABEL)
	
	IF(TARGET_LIBRARIES)
		LINK_INTERNAL(${LIB_NAME} ${TARGET_LIBRARIES})
	ENDIF()

	IF(TARGET_EXTERNAL_LIBRARIES)
		LINK_EXTERNAL(${LIB_NAME} ${TARGET_EXTERNAL_LIBRARIES})
	ENDIF()

	IF(TARGET_LIBRARIES_VARS)
		LINK_WITH_VARIABLES(${LIB_NAME} ${TARGET_LIBRARIES_VARS})
	ENDIF(TARGET_LIBRARIES_VARS)

	LINK_CORELIB_DEFAULT(${LIB_NAME})

	INCLUDE(ModuleInstall OPTIONAL)

	SETUP_LINK_LIBRARIES()

	LINK_LIBRARIES_RD()

ENDMACRO(SETUP_LIBRARY LIB_NAME)

#################################################################################################################
# this is the macro for example and application setup
###########################################################

MACRO(SETUP_EXE IS_COMMANDLINE_APP)
	#MESSAGE("in -->SETUP_EXE<--${TARGET_NAME}-->${TARGET_SRC} <--> ${TARGET_H}<--")

	IF( NOT TARGET_TARGETNAME )
		IF( ${PROJECT_NAME}_USE_FOLDERS )
			SET( TARGET_TARGETNAME "${TARGET_NAME}" )
		ELSE( ${PROJECT_NAME}_USE_FOLDERS )
			SET( TARGET_TARGETNAME "${TARGET_DEFAULT_PREFIX}${TARGET_NAME}" )
		ENDIF( ${PROJECT_NAME}_USE_FOLDERS )
	ENDIF( NOT TARGET_TARGETNAME )

#	message( ${PROJECT_NAME}_USE_FOLDERS " " ${${PROJECT_NAME}_USE_FOLDERS} )

	IF(NOT TARGET_LABEL)
		SET(TARGET_LABEL "${TARGET_DEFAULT_LABEL_PREFIX} ${TARGET_NAME}")
	ENDIF(NOT TARGET_LABEL)

	IF(${IS_COMMANDLINE_APP})
		ADD_EXECUTABLE(${TARGET_TARGETNAME} ${TARGET_SRC} ${TARGET_H})
	ELSE(${IS_COMMANDLINE_APP})
		IF(WIN32)
			IF (REQUIRE_WINMAIN_FLAG)
				SET(PLATFORM_SPECIFIC_CONTROL WIN32)
			ENDIF(REQUIRE_WINMAIN_FLAG)
		ENDIF(WIN32)
		ADD_EXECUTABLE(${TARGET_TARGETNAME} ${PLATFORM_SPECIFIC_CONTROL} ${TARGET_SRC} ${TARGET_H})
	ENDIF(${IS_COMMANDLINE_APP})


	IF( ${PROJECT_NAME}_USE_FOLDERS )
		SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER ${TARGET_DEFAULT_LABEL_PREFIX})
	ENDIF( ${PROJECT_NAME}_USE_FOLDERS )

	SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_TARGETNAME}")
	SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES OUTPUT_NAME ${TARGET_NAME})
	SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES DEBUG_OUTPUT_NAME "${TARGET_NAME}${CMAKE_DEBUG_POSTFIX}")
	SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RELEASE_OUTPUT_NAME "${TARGET_NAME}${CMAKE_RELEASE_POSTFIX}")
	SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RELWITHDEBINFO_OUTPUT_NAME "${TARGET_NAME}${CMAKE_RELWITHDEBINFO_POSTFIX}")
	SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES MINSIZEREL_OUTPUT_NAME "${TARGET_NAME}${CMAKE_MINSIZEREL_POSTFIX}")
	
	IF(MSVC_IDE AND ${PROJECT_NAME}_MSVC_VERSIONED_DLL)
		SET_OUTPUT_DIR_PROPERTY_260(${TARGET_TARGETNAME} "")        # Ensure the /Debug /Release are removed
	ENDIF(MSVC_IDE AND ${PROJECT_NAME}_MSVC_VERSIONED_DLL)

	SETUP_LINK_LIBRARIES()

	LINK_LIBRARIES_RD()

ENDMACRO(SETUP_EXE)

# 改成函数，可以实现在一个文件内进行多次调用，而宏只能调用一次
# Takes optional second argument (is_commandline_app?) in ARGV1
MACRO(SETUP_PROJECT TARGET_NAME)

	SET( TARGET_NAME ${TARGET_NAME} )

	IF(${ARGC} GREATER 1)
	SET(IS_COMMANDLINE_APP ${ARGV1})
	ELSE(${ARGC} GREATER 1)
	SET(IS_COMMANDLINE_APP 0)
	ENDIF(${ARGC} GREATER 1)

	SETUP_EXE(${IS_COMMANDLINE_APP})

ENDMACRO(SETUP_PROJECT)

MACRO(SETUP_COMMANDLINE_PROJECT TARGET_NAME)

	SETUP_PROJECT(${TARGET_NAME} 1)

ENDMACRO(SETUP_COMMANDLINE_PROJECT)

# 一个cmakelists文件内，配置多个工程，主要考虑某些工程可能会有很多例子，把例子一起加进来
FUNCTION(SETUP_MUTIPROJECT TARGET_NAME)

	SETUP_PROJECT( ${TARGET_NAME} )

ENDFUNCTION(SETUP_MUTIPROJECT)

MACRO(REMOVE_CXX_FLAG flag)
	STRING(REPLACE "${flag}" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
ENDMACRO()


# 获取当前相对源码顶层的路径
MACRO( GET_CURRENT_RELATIVE_DIRECTORY CURRENT_RELATIVE_DIRECTORY )
	STRING( REGEX REPLACE "${PROJECT_SOURCE_DIR}/(.*)" "\\1" CURRENT_RELATIVE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} )
ENDMACRO( GET_CURRENT_RELATIVE_DIRECTORY CURRENT_RELATIVE_DIRECTORY )


# 获取当前文件夹
MACRO( GET_CURRENT_FOLDER CURRENT_FOLDER )
	STRING( REGEX REPLACE ".*/(.*)" "\\1" CURRENT_FOLDER ${CMAKE_CURRENT_SOURCE_DIR} )
ENDMACRO( GET_CURRENT_FOLDER CURRENT_FOLDER )


# 获取所有子文件夹
FUNCTION( GET_SUBFOLDERS_BY_POSTFIX SUB_FOLDERS POSTFIX )

	FILE(GLOB_RECURSE DIRS "*.${POSTFIX}")

	# fliter duplicates projects
	FOREACH(DIR ${DIRS})
#		MESSAGE("DIR: " ${DIR})
		STRING( REGEX REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/(.*)/.*.${POSTFIX}$" "\\1" SUB_FOLDER ${DIR} )

# 有两种情况：
# 1、没匹配到，会设置为${DIR}
# 2、匹配到多级目录，如dir/dir
		IF( ${SUB_FOLDER} MATCHES "/" )
#			MESSAGE(STATUS "SUB_FOLDER MATCHES /, CONTINUE..." )
#			MESSAGE("")
			CONTINUE()
		ENDIF( ${SUB_FOLDER} MATCHES "/" )
#		MESSAGE("SUB_FOLDER: " ${SUB_FOLDER} )

		LIST(APPEND RESULT ${SUB_FOLDER} )

#		MESSAGE("")
	ENDFOREACH(DIR ${DIRS})

	SET( ${SUB_FOLDERS} ${RESULT} PARENT_SCOPE )

ENDFUNCTION( GET_SUBFOLDERS_BY_POSTFIX SUB_FOLDERS POSTFIX )


INCLUDE(list_handle)
# 添加所有子文件夹
FUNCTION( ADD_SUBDIRECTORYS_BY_POSTFIX POSTFIX )

	#获取当前文件夹
	GET_CURRENT_FOLDER( CURRENT_FOLDER )
#	MESSAGE(STATUS "CURRENT_FOLDER: ${CURRENT_FOLDER}" )

	# 获取所有子文件夹
	GET_SUBFOLDERS_BY_POSTFIX( SUB_FOLDERS ${POSTFIX})
#	MESSAGE(STATUS "SUB_FOLDERS: ${SUB_FOLDERS}" )

	# 添加每个子文件夹
	FOREACH( subfolder ${SUB_FOLDERS} )

		CDR( SUB_FOLDERS ${SUB_FOLDERS} )
		ADD_SUBDIRECTORY(${subfolder})
		MESSAGE(STATUS "CURRENT_FOLDER: ${CURRENT_FOLDER}--> ADD_SUBDIRECTORY: ${subfolder}")

	ENDFOREACH( subfolder ${SUB_FOLDERS} )

ENDFUNCTION( ADD_SUBDIRECTORYS_BY_POSTFIX POSTFIX )

# 链接找到的库文件
MACRO( LINK_LIBRARIES_RD )
	SET( TARGET_LIBRARIES_RD ${TARGET_COMMON_LIBRARIES_RD} )

	FOREACH( LINKLIB ${TARGET_ADDED_LIBRARIES_RD} )
		SET( TO_INSERT TRUE )
		FOREACH ( value ${TARGET_COMMON_LIBRARIES_RD} )
			IF( ${value} STREQUAL ${LINKLIB} )
			      SET(TO_INSERT FALSE)
			ENDIF( ${value} STREQUAL ${LINKLIB} )
			ENDFOREACH( value ${TARGET_COMMON_LIBRARIES_RD} )
		IF( TO_INSERT )
			LIST( APPEND TARGET_LIBRARIES_RD ${LINKLIB} )
		ENDIF( TO_INSERT )
	ENDFOREACH( LINKLIB ${TARGET_ADDED_LIBRARIES_RD} )

	FOREACH( LIBRARY ${TARGET_LIBRARIES_RD} )
		STRING( TOUPPER ${LIBRARY} LIBRARY_UC )
		IF( ${LIBRARY_UC}_FOUND )
#			LIST( GET ${LIBRARY_UC}_LIBRARIES 1 LIBRARY_R )
#			LIST( GET ${LIBRARY_UC}_LIBRARIES 3 LIBRARY_D )
#			message( "LIBRARY_R: " ${LIBRARY_R} )
#			message( "LIBRARY_D: " ${LIBRARY_D} )
			TARGET_LINK_LIBRARIES( ${TARGET_TARGETNAME} ${${LIBRARY_UC}_LIBRARIES} )
		ENDIF( ${LIBRARY_UC}_FOUND )
	ENDFOREACH( LIBRARY ${TARGET_LIBRARIES_RD} )
ENDMACRO( LINK_LIBRARIES_RD )

#添加项目依赖
MACRO( APPEND_DEPENDENCIES DEPENDENCIES )

	FOREACH( DEPENDENCE ${DEPENDENCIES} )
		ADD_DEPENDENCIES( ${TARGET_TARGETNAME} ${DEPENDENCE} )
	ENDFOREACH( DEPENDENCE ${DEPENDENCIES} )

ENDMACRO( APPEND_DEPENDENCIES )

#
MACRO(SOURCE_GROUP_BY_DIR SOURCE_FILES)
	IF(MSVC)
		SET(SGBD_CUR_DIR ${CMAKE_CURRENT_SOURCE_DIR})
		FOREACH(SGBD_FILE ${${SOURCE_FILES}})
			STRING(REGEX REPLACE ${SGBD_CUR_DIR}/.*\\1 SGBD_FPATH ${SGBD_FILE})
			STRING(REGEX REPLACE ".*/.*" \\1 SGBD_GROUP_NAME ${SGBD_FPATH})
			STRING(COMPARE EQUAL ${SGBD_FPATH} ${SGBD_GROUP_NAME} SGBD_NOGROUP)
			STRING(REPLACE "/" "\\" SGBD_GROUP_NAME ${SGBD_GROUP_NAME})
			IF(SGBD_NOGROUP)
				SET(SGBD_GROUP_NAME "\\")
			ENDIF(SGBD_NOGROUP)
			SOURCE_GROUP(${SGBD_GROUP_NAME} FILES ${SGBD_FILE})
		ENDFOREACH(SGBD_FILE)
	ENDIF(MSVC)
ENDMACRO(SOURCE_GROUP_BY_DIR)


# https://stackoverflow.com/questions/37434946/how-do-i-iterate-over-all-cmake-targets-programmatically
# 递归获取目录下所有targets
function(get_all_targets var)
    set(targets)
	if(${ARGC} GREATER 1)
	   set(get_all_targets_dir ${ARGV1})
	else(${ARGC} GREATER 1)
	   set(get_all_targets_dir ${CMAKE_CURRENT_SOURCE_DIR})
	endif(${ARGC} GREATER 1)

    get_all_targets_recursive(targets ${get_all_targets_dir})
    set(${var} ${targets} PARENT_SCOPE)
endfunction()

# 递归获取目录下所有targets
macro(get_all_targets_recursive targets dir)
    get_property(subdirectories DIRECTORY ${dir} PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
        message(${subdir})
        get_all_targets_recursive(${targets} ${subdir})
    endforeach()

    get_property(current_targets DIRECTORY ${dir} PROPERTY BUILDSYSTEM_TARGETS)
    list(APPEND ${targets} ${current_targets})
endmacro()

# 将其内部target放入工程结构label_prefix文件夹内
function( set_targets_group_property_prefix module_dir group_property_prefix )
    get_all_targets( targets ${module_dir} )
    foreach(target ${targets})
        get_target_property( property ${target} FOLDER )
        if( ${property} STREQUAL "property-NOTFOUND" )
            set( property ${group_property_prefix}/${module_dir} )
        else()
            set( property ${group_property_prefix}/${property} )
        endif()
        set_target_properties( ${target} PROPERTIES FOLDER ${property} )
        message( "add ${property}/${target}" )
    endforeach()
endfunction()

