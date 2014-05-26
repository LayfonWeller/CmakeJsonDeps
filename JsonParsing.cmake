#The MIT License (MIT)
#
#Copyright (c) 2014 LayfonWeller
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

# Create and call a json parser that will create a cmake file containing the cmake equivalent of the json
# Also gives tools to navigate in the cmakefied json
#
# Author : Mathieu Giguere (alias Layfon Weller)
#

set (jsonParsingSourceFile ${CMAKE_CURRENT_LIST_DIR}/JsonParsing/json2Cmake.cpp CACHE "" INTERNAL FORCE)

include (CMakeParseArguments)
macro (ParseJson jsonFile)
	set(options )
	set(oneValueArgs PREFIX ROOT)
	set(multiValueArgs )
	CMAKE_PARSE_ARGUMENTS (ParseJson "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	if (NOT ("${ParseJson_PREFIX}" STREQUAL ""))
		set (prefix ${ParseJson_PREFIX})
	else ()
		get_filename_component(prefix ${jsonFile} NAME_WE)
	endif ()
	
	try_run(
		run_result_unused
		builded 
		${CMAKE_BINARY_DIR}/json ${jsonParsingSourceFile}
		ARGS ${jsonFile} ${prefix} ${PROJECT_BINARY_DIR}/json/${prefix}.cmake
	)
	include (${PROJECT_BINARY_DIR}/json/${prefix}.cmake)
	if (NOT ( "${ParseJson_ROOT}" STREQUAL ""))
		set (${ParseJson_ROOT} jsonParsed_${prefix})
	endif ()
	
	CONFIGURE_FILE(
		${jsonFile}
		${PROJECT_BINARY_DIR}/json/${prefix}.tmp
	)
		
endmacro ()

macro (isObject root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "OBJECT")
		set (${return} TRUE) 
	else ()
		set (${return} FALSE) 
	endif ()
endmacro ()

macro (isValue root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "VALUE")
		set (${return} TRUE) 
	else ()
		set (${return} FALSE) 
	endif ()
endmacro ()

macro (isArray root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "ARRAY")
		set (${return} TRUE) 
	else ()
		set (${return} FALSE) 
	endif ()
endmacro ()

macro (isJson root return)
        set(${return} FALSE)
        isObject(${root} is )
        if (is)
            set(${return} TRUE)
        endif ()
        isValue(${root} is)
        if (is)
            set(${return} TRUE)
        endif ()
        isArray(${root} is)
        if (is)
            set(${return} TRUE)
        endif ()
endmacro ()


macro (GetValue root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "VALUE")
		LIST(GET ${root} 1 ${return})
	else ()
		set (${return} "NOTAVALUE")
	endif ()
endmacro ()

macro (GetObjectElementName root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "OBJECT")
		set (${return} ${${root}})
		LIST (REMOVE_AT ${return} 0)
	else ()
		set (${return} "NOTANOBJECT")
	endif ()
endmacro ()

macro (GetArraySize root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "ARRAY")
		LIST(GET ${root} 1 ${return})
	else ()
		set (${return} "NOTANARRAY")
	endif ()
endmacro ()

macro (GetObjectElement root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "OBJECT")
		set (tmp ${${root}})
		set (${return} "")
		LIST (REMOVE_AT tmp 0)
		foreach (el IN LISTS tmp)
			LIST (APPEND ${return} ${root}_${el})
		endforeach ()
	else ()
		set (${return} "INNOTANOBJECT")
	endif ()
endmacro ()

macro (GetArray root return)
	LIST(GET ${root} 0 type)
	if ("${type}" STREQUAL "ARRAY")
		GetArraySize(${root} size)
		set (${return} "")
		MATH (EXPR size "${size} - 1")
		foreach (arrayEl RANGE ${size})
			LIST (APPEND ${return} ${root}_${arrayEl})
		endforeach ()
	else ()
		set (${return} "ISNOTANARRAY")
	endif ()
endmacro ()

macro (GetElement root elementPath return)
	STRING(REPLACE "." "_" elementPath2 ${elementPath})
	set (${return} ${root}_${elementPath2})
endmacro ()
