include (JsonParsing)


macro (GetTag PRIMARY SECONDARY TAG RETVAL)
    set(${RETVAL} FALSE )
    #message(STATUS "PRIMARY ${PRIMARY} SECONDARY : ${SECONDARY} tag : ${TAG} RETVAL = ${RETVAL}")
	foreach (loc ${PRIMARY} ${SECONDARY})
		#message(STATUS "Hello loc ${loc} tag : ${TAG}")
       GetElement(${loc} ${TAG} possibleLoc)
       isJson(${possibleLoc}  isItJson)
       #message(STATUS "PossibleLoc : ${possibleLoc} isJson = [${isItJson}]")
       if (isItJson)
          set (${RETVAL} ${possibleLoc} )
          break ()
       endif ()
    endforeach ()
endmacro ()


macro (Json_Deps depsList)

	find_package(Hg QUIET)
	find_package(Subversion QUIET)
	find_package(Git QUIET)
 
    cmake_minimum_required(VERSION 2.8.10 FATAL_ERROR)

	include (ExternalProject)
	
	#tmp solution to prefix
	set (prefix ${PROJECT_BINARY_DIR}/deps)
	
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)
	#message (STATUS "DEPS LIST : ${depsList} : ${${depsList}}")
	foreach (dep IN LISTS ${depsList}) 
		#message(STATUS "Looking for ${dep}")
		isObject (${dep} isItObject)
		if (isItObject)
			GetElement(${dep} "name" NameNode)
			GetElement(${dep} "OS"  OSNode)
			
			isValue (${NameNode} isNameValue)
			if (isNameValue)
				getValue(${NameNode} 	name)
				message(STATUS "Looking for dep : ${name}")

				
				isValue (${OSNode} hasOsValue)
				isArray (${OSNode} hasOsArray)
				#DONE : Make a NOT keyword to specify all but an OS (NOT changed for !)
				
				if (hasOsValue)
					getValue (${OSNode} ${dep}_OSList)
				elseif (hasOsArray)
					getArray(${OSNode} ${dep}_OSListArray)
					foreach (os IN LISTS ${dep}_OSListArray)
                        isValue(${os} osArrayIsValue )
                        if (osArrayIsValue)
						   getValue(${os} osName)
                        else ()
                           isObject(${os} osIsObject)
                           if (osIsObject)
                              GetObjectElementName(${os} osName )
                              set(${dep}_${osName}_isObject TRUE)
                              set(${dep}_${osName}_Object ${os})
                           else ()
                              message (ERROR "OS was neither an array of value or object!")
                           endif ()
                        endif ()
						LIST (APPEND ${dep}_OSList ${osName})
					endforeach ()
				endif ()
				
				set (${dep}RELEVANT TRUE)
				if (${dep}_OSList)
					message (STATUS "Checking ${name} is go on this platform [Running : ${CMAKE_SYSTEM}][Looking for : ${${dep}_OSList}]")
					set (${dep}RELEVANT FALSE) 
					foreach (os IN LISTS ${dep}_OSList)
						set (${dep}_LastOSChecked ${os})						
						string (TOUPPER ${os} CheckingOS )
						if (WIN32)
							if ("${CheckingOS}" STREQUAL "WIN32") #TODO : Only when targetting x32
								set (${dep}RELEVANT TRUE)
                                break ()
							endif ()
							if ("${CheckingOS}" STREQUAL "WIN64") #TODO : Only when targetting x64
								set (${dep}RELEVANT TRUE)
								break ()
							endif ()
							if ("${CheckingOS}" STREQUAL "WIN")
								set (${dep}RELEVANT TRUE)
								break ()
							endif ()
							if ("${CheckingOS}" STREQUAL "!WIN")
								set (${dep}RELEVANT FALSE)
								break ()
							endif ()
						elseif (APPLE)
							if ("${CheckingOS}" STREQUAL "APPLE")
								set (${dep}RELEVANT TRUE)
								break ()
							endif ()
							if ("${CheckingOS}" STREQUAL "!APPLE")
								set (${dep}RELEVANT FALSE)
                                break ()
							endif ()
						else ()
							if ("${CheckingOS}" STREQUAL "UNIX")
								set (${dep}RELEVANT TRUE)
								break ()
							endif ()
							if ("${CheckingOS}" STREQUAL "!UNIX")
								set (${dep}RELEVANT FALSE)
								break ()
							endif ()
						endif ()
					endforeach ()
                    if (${dep}_${${dep}_LastOSChecked}_isObject)
                        GetElement(${${dep}_${osName}_Object} ${${dep}_LastOSChecked} ${dep}_OSSpecificNode)
                    endif ()
				endif ()
				#message (STATUS "${name} is going to be compiled on this platform (${CMAKE_SYSTEM}) : ${${dep}RELEVANT}")
                if (${dep}RELEVANT)
					#TODO Check first for in OS element if present, if value not found in the OS element, go and check at the object root
                    GetTag("${${dep}_OSSpecificNode}" "${dep}" "type" TypeNode)
  	                GetTag("${${dep}_OSSpecificNode}" "${dep}" "url"  UrlNode )
           	        GetTag("${${dep}_OSSpecificNode}" "${dep}" "version"  VersionNode)
                   	GetTag("${${dep}_OSSpecificNode}" "${dep}" "depends"  DepsArrayNode)


                   #	message(STATUS "UrlNode ${UrlNode} | VersionNode = ${VersionNode} | DepsArrayNode = ${DepsArrayNode}")

                    isValue (${TypeNode} isTypeValue)
                    isValue (${UrlNode}  isUrlValue )

					if (isTypeValue AND isUrlValue)
					    getValue(${TypeNode}    gettingMethod)
                        string (TOUPPER ${gettingMethod} gettingMethod )
                        getValue(${UrlNode}      url)
    	                getValue(${VersionNode}  version)


                	    #TODO check if locally installed and if compiled!
			
						#if () #DEAL with prefix!
							set (${dep}_prefix "${prefix}/${name}")
						#else ()
						#endif ()
					
						#Deal with install place
						set (${dep}_InstallLoc "${prefix}/install")
				
						#look for cmake file
						find_file (${name}_IMPORT 
							NAMES ${name}_import.cmake
							HINTS ${${dep}_InstallLoc}
						)
						#if (${name}_IMPORT)
						#	include(${${name}_IMPORT})
						#	break ()
						#endif ()
						#find_package(${name})
						#if (${name}_FOUND)
						#	#TODO : DO STUFF
						#	break ()
						#endif ()
				
						#We have not found the package! let's get it's source and compile it
					
						set (depDeps "")
						isArray (${DepsArrayNode} hasDeps)
						if (hasDeps)
							GetArray( ${DepsArrayNode} DepArray)
							foreach (depdep IN LISTS DepArray)
								getValue(${depdep} depName)
								LIST (APPEND depDeps ${depName})
							endforeach ()
							message (STATUS "[${name}:${version}:${gettingMethod}:${url}][${depDeps}]")
							set (${dep}_deps0 "DEPENDS")
							set (${dep}_deps1 "${depDeps}")
						else ()
							message (STATUS "[${name}:${version}:${gettingMethod}:${url}]")
							set (${dep}_deps "")
						endif ()
					
						if ("${gettingMethod}" STREQUAL "HG")
							set (${dep}_down0 "HG_REPOSITORY")
							set (${dep}_down1 "${url}")
							#Get tags
							GetTag("${${dep}_OSSpecificNode}" "${dep}" "tag" depTag_node)
							isValue (${depTag_node} depHasATag)
							if (depHasATag)
								getValue(${depTag_node} depTag)
								set (${dep}_down2 "HG_TAG")
								set (${dep}_down3 "${depTag}")
							endif ()
							set (${dep}_patch_cmd ${HG_EXECUTABLE} import --no-commit ${PROJECT_SOURCE_DIR}/@${dep}_patchFile@ || \( echo "Could not apply patch, might be because it's already applied" && exit 0 \))
						elseif ("${gettingMethod}" STREQUAL "DOWNLOAD")
							if(NOT HG_EXECUTABLE)
								message(FATAL_ERROR "error: could not find hg for clone of ${name}")
							endif()
							set (${dep}_down0 "URL")
							set (${dep}_down1 "${url}")
							GetTag("${${dep}_OSSpecificNode}" "${dep}" "validation" depVAL_node)
							isObject (${depVAL_node} depHasVal)
							if (depHasVal)
								GetElement(${depVAL_node} "algo" depVAL_algo_node)
								GetElement(${depVAL_node} "value" depVAL_value_node)
								isValue(${depVAL_algo_node}  depVAL_hasAlgo)
								isValue(${depVAL_value_node} depVAL_hasValue)
								if (depVAL_hasAlgo AND depVAL_hasValue)
									getValue(${depVAL_algo_node}  depVAL_Algo)
									getValue(${depVAL_value_node} depVAL_Value)
									set (${dep}_down2 "URL_HASH")
									set (${dep}_down3 "${depVAL_Algo}=${depVAL_Value}")
								endif ()
							endif ()
							set (${dep}_patch_cmd ${HG_EXECUTABLE} import --no-commit ${PROJECT_SOURCE_DIR}/@${dep}_patchFile@ || \( echo "Could not apply patch, might be because it's already applied" && exit 0 \))
						elseif ("${gettingMethod}" STREQUAL "GIT")
							set (${dep}_down0 "GIT_REPOSITORY")
							set (${dep}_down1 "${url}")
							GetTag("${${dep}_OSSpecificNode}" "${dep}" "tag" depTag_node)
							isValue (${depTag_node} depHasATag)
							if (depHasATag)
								getValue(${depTag_node} depTag)
								set (${dep}_down2 "$GIT_TAG")
								set (${dep}_down3 "${depTag}")
							endif ()
							set (${dep}_patch_cmd ${GIT_EXECUTABLE} apply ${PROJECT_SOURCE_DIR}/@${dep}_patchFile@ || \( echo "Could not apply patch, might be because it's already applied" && exit 0 \))
						elseif ("${gettingMethod}" STREQUAL "SVN")
							set (${dep}_down0 "SVN_REPOSITORY")
							set (${dep}_down1 "${url}")
							GetTag("${${dep}_OSSpecificNode}" "${dep}" "tag" depTag_node)
							isValue (${depTag_node} depHasATag)
							if (depHasATag)
								getValue(${depTag_node} depTag)
								set (${dep}_down2 "SVN_REVISION")
								set (${dep}_down3 "${depTag}")
							endif ()
							set (${dep}_patch_cmd ${SVN_EXECUTABLE} apply ${PROJECT_SOURCE_DIR}/@${dep}_patchFile@ || \( echo "Could not apply patch, might be because it's already applied" && exit 0 \))
						endif ()
				
						#Patch
						GetTag("${${dep}_OSSpecificNode}" "${dep}" "patch" depPatch_node)
						isValue (${depPatch_node} ${dep}_HasPatch)
						if (${dep}_HasPatch)
							getValue (${depPatch_node} ${dep}_patchFile)
							set (${dep}_patch0 "PATCH_COMMAND")
							STRING(CONFIGURE "${${dep}_patch_cmd}" ${dep}_patch1 @ONLY)
							message (STATUS "Patch Cmd : ${${dep}_patch1}")
						endif ()
					
					
						#CMAKE parameters
						GetTag("${${dep}_OSSpecificNode}" "${dep}" "CMAKE_ARGS" depCmakeArg_Node)
						isArray (${depCmakeArg_Node} depCmakeArg_isArray)
						isValue (${depCmakeArg_Node} depCmakeArg_isValue)
						if (depCmakeArg_isArray)
							getArray(${depCmakeArg_Node} CmakeArgsArray)
							set (${dep}_cmakeArgs0 "CMAKE_ARGS")
							foreach (cmakeArgNode IN LISTS CmakeArgsArray)
								getValue(${cmakeArgNode} cmakeArg)
								list (APPEND ${dep}_cmakeArgs1 ${cmakeArg})
							endforeach ()
						elseif (depCmakeArg_isValue)
							getValue ({depCmakeArg_Array_Node} cmakeArg)
							set (${dep}_cmakeArgs0 "CMAKE_ARGS ")
							set (${dep}_cmakeArgs1 ${cmakeArg})
						endif ()
				
						#TODO : Run configure string
					
#						message ("ExternalProject_Add (${name}\n"
#						"	PREFIX ${${dep}_prefix}\n"
#						"	${${dep}_deps0} ${${dep}_deps1}\n"
#						"	${${dep}_down0} ${${dep}_down1}\n"
#						"	${${dep}_down2} ${${dep}_down3}\n"
#						"	${${dep}_patch0} ${${dep}_patch1}\n"
#						"	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:path=\"${${dep}_InstallLoc}\"\n"
#						"	-DCMAKE_PREFIX_PATH:PATH=\"${${dep}_InstallLoc}\"\n"
#						"	${${dep}_cmakeArgs1}\n"
#						")\n")
						ExternalProject_Add (${name}
							PREFIX ${${dep}_prefix}
							${${dep}_deps0} ${${dep}_deps1} 
							${${dep}_down0} ${${dep}_down1} 
							${${dep}_down2} ${${dep}_down3} 
							${${dep}_patch0} ${${dep}_patch1}		
							CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${${dep}_InstallLoc}
							-DCMAKE_PREFIX_PATH:PATH=${${dep}_InstallLoc}
							${${dep}_cmakeArgs1}
							CMAKE_CACHE_ARGS 
							${${dep}_cmakeArgs1}
						)
						set_property(TARGET ${name} PROPERTY FOLDER "Deps")
					
						if (DEFINED ${dep}_patch0 AND "${gettingMethod}" STREQUAL "DOWNLOAD")
							ExternalProject_Add_Step(${name} hginit
								COMMAND ${HG_EXECUTABLE} init || \( echo \"Could not init, might already be\" && exit 0 \)
								COMMAND ${HG_EXECUTABLE} ci -A -u dev -m "PrePatch" || \( echo "Could not commit, might already be" && exit 0 \)
								DEPENDEES  download
								DEPENDERS patch 
								WORKING_DIRECTORY <SOURCE_DIR>
							)
							ExternalProject_Add_Step(${name} backup
								COMMAND \( ${HG_EXECUTABLE} diff > ${PROJECT_BINARY_DIR}/${name}.bak.patch && echo "Backuped changes to ${PROJECT_BINARY_DIR}/${name}.bak.patch" \)  || \( echo "Could not backup changes" && exit 0 \)
								DEPENDEES  hginit
								DEPENDERS patch 
								WORKING_DIRECTORY <SOURCE_DIR>
							)
							ExternalProject_Add_Step(${name} revert
								COMMAND  ${HG_EXECUTABLE} revert -a || \( echo "Could not revert, might have nothing to revert" && exit 0 \)
								DEPENDEES backup 
								DEPENDERS patch 
								WORKING_DIRECTORY <SOURCE_DIR>
							)
#							ExternalProject_Add_Step(${name} hgci
#								
#								DEPENDEES  revert
#								DEPENDERS patch 
#								WORKING_DIRECTORY <SOURCE_DIR>
#							)
							#message ("Step Added!")
						endif ()
						if (DEFINED ${dep}_patch0 AND "${gettingMethod}" STREQUAL "HG")

							ExternalProject_Add_Step(${name} revert
								COMMAND ${HG_EXECUTABLE} revert -a || \( echo "Could not revert, might have nothing to revert" && exit 0 \)
								DEPENDEES backup 
								DEPENDERS patch 
								WORKING_DIRECTORY <SOURCE_DIR>
							)
							ExternalProject_Add_Step(${name} backup
								COMMAND \( ${HG_EXECUTABLE} diff > ${PROJECT_BINARY_DIR}/${name}.bak.patch && echo "Backuped changes to ${PROJECT_BINARY_DIR}/${name}.bak.patch" \)  || \( echo "Could not backup changes" && exit 0 \)
								DEPENDEES download 
								DEPENDERS revert 
								WORKING_DIRECTORY <SOURCE_DIR>
							)
						endif ()
					endif ()
				endif ()
			else ()
				message ("This Dep does not have a name")
			endif ()
		else ()
			message ("This Json Value is not a valid dependancy : ${dep}")
		endif ()
	endforeach ()
endmacro ()



