﻿SET( CURRENT_FINDING_NAME vermilion )
SET( CURRENT_FINDING_INCLUDE_FILE vermilion.h )
SET( CURRENT_FINDING_LIBRARY_FILE vermilion )

include(${CMAKE_CURRENT_LIST_DIR}/FindUtils.cmake)

SL_FIND_INCLUDE_PATH( ${CURRENT_FINDING_NAME} ${CURRENT_FINDING_INCLUDE_FILE} )
SL_FIND_LIBRARY_RD( ${CURRENT_FINDING_NAME} ${CURRENT_FINDING_LIBRARY_FILE} )