# Module support documentation
This software supports external modules written in Lua/Moonscript through the Module API.  
Modules are installed in the `modules` folder, as their own folder and use the following structure:  
- `module.pack` (described bellow)
- `res/` (optional resource folder)
- `config.json` (module configuration file)
- `module.info` (described bellow)

An utility to create modules is available at [natnat-mc/imglib-mkmodule](https://github.com/natnat-mc/imglib-mkmodule).

## `module.pack`
The `module.pack` is a JSON object mapping filename to file content. It is loaded in memory when the module is loaded and used by the `require` and `getobj` functions.  
All the module code should be packaged in this file.  
The JSON object is flat, but filenames are namespaced with `/` (but don't start with `/`)

## `module.info`
The `module.info` is a JSON object containing the following properties:  
- `name` (module name, string)
- `entrypoint` (key in the `module.pack` that should be loaded first, formatted like a call to `require`, string)
- `version` (module version, semver string)

## The Module API
The Module API exposes a `module` global object and the functions `require(path)` and `getobj(path)` to loaded modules, containing the following properties and methods:

### `require(path)`
Loads another submodule from the `module.pack` relative to the current submodule, or a dependency of the main app.

- If `path` starts with `/`, the submodule is loaded from the root of the pack
- If `path` starts with `.`, the submodule is loaded relatively from the current submodule
- Otherwise, a dependency of the main app is loaded

### `getobj(path)`
Retrieves a value from the `module.pack` relative to to the current submodule

- If `path` starts with `/`, the value is loaded from the root of the pack
- If `path` starts with `.`, the value is loaded relatively from the current submodule

### `module.exports`
Originally an empty table, but can be populated with objects or functions to expose to other modules

### `module.preinit`
Originally nil, but can be overwritten with a function at first load so that it will be called when all modules are first loaded

### `module.init`
Originally nil, but can be overwritten before or during preinit so that it will be called when all modules finished their preinit

### `module.name`
*Read-only*  
The name of the current module

### `module.version`
*Read-only*  
The version of the current module

### `module.respath`
*Read-only*  
The path of the module's `res/` folder if it exists, `nil` otherwise

### `module.config`
*Read-only*  
The module's configuration object

### `module.saveconfig()`
*Read-only*  
Writes the module config to disk

### `module.get(name)`
*Read-only*  
Returns the `module.exports` of a loaded module

### `module.loaded()`
*Read-only*  
Returns an iterator that lists all loaded modules

### `module.addapi(method, path, handler)`
*Read-only*  
Adds a route to the API, with the given method, path and handler

### `module.addrouter(path, handler)`
*Read-only*
Adds a router to the MoonCake server

### `module.db`
*Read-only*  
The app's `db` module

### `module.api`
*Read-only*  
A table containing the following fields:  
- `auth` (low-level authentication module)
- `authenticate` (high-level authentication module)
- `getquery` (querystring/JSON validation module)

### `module.native`
*Read-only*  
The app's `native` module
