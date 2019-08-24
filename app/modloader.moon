fs=require 'fs'
JSON=require 'JSON'
simplifypath=require '../libs/simplifypath'

objects={}
modules={}

--BEGIN public module object
modulepublic={}
modulepublic.get=(module) ->
	mod=modules[module]
	error "Module #{module} not found" unless mod
	return rawget mod, 'exports'

modulepublic.loaded=() ->
	return coroutine.wrap () ->
		coroutine.yield k, v.version for k, v in pairs modules

modulepublic.addapi=(method, path, handler) ->
	objects.api method, path, handler

modulepublic.addrouter=(path, handler) ->
	objects.mcserver\use (req, res, next) ->
		return next! if path!=req.url\sub 1, #path
		realurl, req.url=req.url, req.url\sub (path=='/' and 1 or #path)
		return handler req, res, () ->
			req.url=realurl
			next!

updateobjects=() ->
	modulepublic.db=objects.db
	modulepublic.native=objects.native
	modulepublic.api={
		auth: objects.auth,
		authenticate: objects.authenticate,
		getquery: objects.getquery
	}
--END public module object

--BEGIN single module loader
loadmodule=(path) ->
	-- load module from disk
	local name, version, entrypoint, pack, config, respath
	do
		import name, version, entrypoint from JSON.parse fs.readFileSync "#{path}/module.info"
		error "Wrong module.info format" unless ('string'==type name) and ('string'==type version) and 'string'==type entrypoint
		pack=JSON.parse fs.readFileSync "#{path}/module.pack"
		config=JSON.parse fs.readFileSync "#{path}/config.json"
		respath=(fs.statSync "#{path}/res") and "#{path}/res" or nil
	
	-- construct module table
	local moduletable
	do
		moduletable={
			exports: {}
			preinit: nil
			init: nil
		}
		moduleprivtable={
			:name, :version, :respath
			:config, saveconfig: () -> fs.writeFileSync "#{path}/config.json", JSON.stringify config
		}
		setmetatable moduletable, {__index: moduleprivtable}
		setmetatable moduleprivtable, {__index: modulepublic}
		modules[name]=moduletable
	
	-- module util functions
	local mkenv
	do
		loadedcache={}
		
		resolve=(current, path, fallthrough) ->
			if '/'==path\sub 1, 1
				return simplifypath path\sub 2
			elseif '.'==path\sub 1, 1
				if current==''
					return simplifypath path
				return simplifypath "#{current}/#{path}"
			elseif fallthrough
				return path, true
			else
				error "Illegal path: must start with '.' or '/'"
		
		getobj=(current, path) ->
			key=resolve current, path
			val=pack[key]
			error "Object not found: #{path} (#{key})" unless val
			return val
		
		require=(current, path) ->
			-- load file from pack or parent
			key, raw=resolve current, path, true
			return objects.require key if raw
			val, file=pack[key], key
			val, file=pack["#{key}.lua"], "#{key}.lua" unless val
			val, file=pack["#{key}/init.lua"], "#{key}/init.lua" unless val
			error "Submodule not found: #{path} (#{key}, in module #{name})" unless val
			
			-- make sure we use the cache if available
			if loadedcache[file]
				return loadedcache[file]
			
			-- load code and prepare it
			env=mkenv file
			fn, err=loadstring val, "sub[#{name}]:#{file}"
			error "Error loading submodule #{path} (#{file}, in module #{name}): #{err}" unless fn
			setfenv fn, env
			
			
			-- run the code and put its result in cache
			ok, ret=pcall fn
			error "Error running submodule #{path} (#{file}, in module #{name}): #{ret}" unless ok
			loadedcache[file]=ret or true
			return ret
		
		mkenv=(currentmod) ->
			dir=simplifypath "#{currentmod}/.."
			env={
				getobj: (path) -> getobj dir, path
				require: (path) -> require dir, path
				module: moduletable
			}
			setmetatable env, {__index: _G}
			return env
	
	do -- load entrypoint
		env=mkenv '__loader'
		env.require entrypoint
--END single module loader

--BEGIN full module loader
loadmodules=() ->
	for dir in *fs.readdirSync './modules'
		if fs.statSync "./modules/#{dir}/module.info"
			loadmodule "./modules/#{dir}"
	
	for k, module in pairs modules
		module.preinit! if module.preinit
	
	for k, module in pairs modules
		module.init! if module.init
--END full module loader

{
	:objects, :updateobjects
	:loadmodules
}
