#.rst:
# Findosg_functions
# -----------------
#
#
#
#
#
# This CMake file contains two macros to assist with searching for OSG
# libraries and nodekits.  Please see FindOpenSceneGraph.cmake for full
# documentation.

#=============================================================================
# Copyright 2009 Kitware, Inc.
# Copyright 2009-2012 Philip Lowman <philip@yhbt.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# Shell Lee
# 2015 10 20
# 修改为一般方法，来寻找头文件以及release debug库文件

#
# SL_FIND_PATH
#
function(SL_FIND_INCLUDE_PATH module header)
	string(TOUPPER ${module} module_uc)

	UNSET( ${module_uc}_INCLUDE_DIR )

	# Try the user's environment request before anything else.
	find_path(${module_uc}_INCLUDE_DIR ${header}
		HINTS
		 	ENV ${module_uc}_DIR
		 	ENV ${module_uc}DIR
		 	ENV ${module_uc}_ROOT
		 	ENV ${module_uc}ROOT
		 	${${module_uc}_DIR}
			${SL_${module_uc}_DIRECTORY}
			${CMAKE_CURRENT_LIST_DIR}/../
			${CMAKE_CURRENT_LIST_DIR}/../../
			${CMAKE_CURRENT_SOURCE_DIR}/
			${CMAKE_CURRENT_SOURCE_DIR}/../
		PATH_SUFFIXES include include/${module} include/${module_uc}
		PATHS
			/sw # Fink
			/opt/local # DarwinPorts
			/opt/csw # Blastwave
			/opt
			/usr/freeware
	)
endfunction()

INCLUDE(LISTHANDLE)

#
# SL_FIND_LIBRARY_RD ( RELEASE AND DEBUG )
#
MACRO( SL_FIND_LIBRARY_RD module library )
	string(TOUPPER ${module} module_uc)

#	message( STATUS "module_uc:" ${module_uc} )
#	message( STATUS "library:" ${library} )

	FOREACH( conf_and_postfix ${LINK_LIBRARY_POSTFIXES} )

#		message( STATUS "conf_and_postfix:" ${conf_and_postfix} )	

#		STRING( REGEX REPLACE "(.*)|(.*)" "\\1" conf "\\2" postfix ${conf_and_postfix} )
#		STRING( REGEX REPLACE "(.*)|.*^" "\\1" conf ${conf_and_postfix} )
#		STRING( REGEX REPLACE ".*|(.*)$" "\\1" postfix ${conf_and_postfix} )

		STRING( REPLACE "|" ";" conf_or_postfix ${conf_and_postfix} )

		CAR( conf ${conf_or_postfix} )
		CDR( postfix ${conf_or_postfix} )
#		CDR( conf_or_postfix ${conf_or_postfix} )
#		CDR( postfix ${conf_or_postfix} )

		IF( ${postfix} MATCHES ${EMPTY_STRING_FLAG} )
			SET( postfix "" )
		ENDIF( ${postfix} MATCHES ${EMPTY_STRING_FLAG} )

#		message( STATUS "conf:" ${conf} )
#		message( STATUS "postfix:" ${postfix} )

		UNSET( ${module_uc}_LIBRARY_${conf} )

#		message( STATUS "begin_find_library( ${module_uc}_LIBRARY_${conf} )" )
		find_library( ${module_uc}_LIBRARY_${conf}
			NAMES ${library}${postfix}
			HINTS
				ENV ${module_uc}_DIR
				ENV ${module_uc}DIR
				ENV ${module_uc}_ROOT
				ENV ${module_uc}ROOT
				${${module_uc}_DIR}
				${CMAKE_CURRENT_SOURCE_DIR}/
				${CMAKE_CURRENT_SOURCE_DIR}/../
				${${module_uc}_INCLUDE_DIR}/../
				${${module_uc}_INCLUDE_DIR}/../../
			PATH_SUFFIXES lib lib/${module} lib/${module_uc}
			PATHS
				/sw # Fink
				/opt/local # DarwinPorts
				/opt/csw # Blastwave
				/opt
				/usr/freeware
		)
#		message( STATUS "end_find_library( ${module_uc}_LIBRARY_${conf} )" ${${module_uc}_LIBRARY_${conf}} )
	ENDFOREACH( conf_and_postfix ${LINK_LIBRARY_POSTFIXES} )

	if(NOT ${module_uc}_LIBRARY_DEBUG)
		# They don't have a debug library
		set( ${module_uc}_LIBRARY_DEBUG ${${module_uc}_LIBRARY_RELEASE} )
		set( ${module_uc}_LIBRARIES ${${module_uc}_LIBRARY_RELEASE} )
	else()
		# They really have a FOO_LIBRARY_DEBUG
		set( ${module_uc}_LIBRARIES
			optimized ${${module_uc}_LIBRARY_RELEASE}
			debug ${${module_uc}_LIBRARY_DEBUG}
		)
	endif()

	SET(${module_uc}_FOUND "NO")
	IF(${module_uc}_LIBRARIES AND ${module_uc}_INCLUDE_DIR)
		SET(${module_uc}_FOUND "YES")
	ELSE()
		SET( SL_${module_uc}_DIRECTORY ${${module_uc}_INCLUDE_DIR} )
	ENDIF()

	MESSAGE( "${module_uc}_FOUND: " ${${module_uc}_FOUND} )
	FOREACH( ITEM ${${module_uc}_LIBRARIES})
		MESSAGE( STATUS ${ITEM} )
	endFOREACH( ITEM ${${module_uc}_LIBRARIES})
ENDMACRO()

#
# OSG_MARK_AS_ADVANCED
# Just a convenience function for calling MARK_AS_ADVANCED
#
function( OSG_MARK_AS_ADVANCED _module )
	string(TOUPPER ${_module} _module_UC)
	mark_as_advanced(${_module_UC}_INCLUDE_DIR)
	mark_as_advanced(${_module_UC}_LIBRARY)
	mark_as_advanced(${_module_UC}_LIBRARY_DEBUG)
endfunction()