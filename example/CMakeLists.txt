cmake_minimum_required(VERSION 2.8.10)
project (ZZLIB_deps)

enable_language (CXX)

MESSAGE("CMAKE_SYSTEM ${CMAKE_SYSTEM}")
MESSAGE("CMAKE_GENERATOR ${CMAKE_GENERATOR}")

set(CMAKE_MODULE_PATH
	${PROJECT_SOURCE_DIR}
	${PROJECT_SOURCE_DIR}/..
	${CMAKE_MODULE_PATH}
)

include (GetJsonParser)
include (JsonParsing)
include (JsonDepsParsing)

ParseJson (${PROJECT_SOURCE_DIR}/zzlib.json ROOT jsonRoot)
GetElement (${jsonRoot} "dependencies" dep_path)
GetArray (${dep_path} deps)
Json_Deps(deps)



