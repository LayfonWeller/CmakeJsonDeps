#CmakeJsonDeps


parse a json array (parsed by CmakeJsonParsing) and add has eternal projects dependencies


## How to use

Parse a json file, get the root to the arrays of deps.
Pass this root to Json_Deps()

`ParseJson (${PROJECT_SOURCE_DIR}/zzlib.json ROOT jsonRoot)`

`GetElement (${jsonRoot} "dependencies" dep_path)`

`GetArray (${dep_path} deps)`

`Json_Deps(deps)`


## Example

See example folder

## Todo

- Document all tags used
- Changes upper-cased tag to lower-case
- Add "option" tag that indicate option in the dependency
-- add option to specify type, optional list of value and default value
- generalise "cmake_args" to "args" or "forced_option"
- add a tag to specify build type (cmake/scons/gyp/..)
-- add configure tag to build type
- Look for file with the dependency name if the dependency (in the depends tag) is not found.
- Go one step farther, and check for a file with the dependency name if the value giving is not complete enough. (this is to allow only setting the name, version if this is all the data needed)
- ? make it closer to npm format?
