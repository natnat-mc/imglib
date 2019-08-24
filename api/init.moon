routelist={
	{'GET', '/version', './GET_version'}
	{'GET', '/status', './GET_status'}
	
	{'POST', '/login', './POST_login'}
	{'GET', '/keys', './GET_keys'}
	{'DELETE', '/keys/:id', './DELETE_keys_id'}
	{'POST', '/changepassword', './POST_changepassword'}
	
	{'GET', '/formats', './GET_formats'}
	{'PUT', '/formats', './PUT_formats'}
	{'GET', '/formats/:id', './GET_formats_id'}
	{'DELETE', '/formats/:id', './DELETE_formats_id'}
	{'GET', '/formats/list', './GET_formats_list'} -- deprecated
	
	{'GET', '/tags', './GET_tags'}
	{'PUT', '/tags', './PUT_tags'}
	{'GET', '/tags/:id', './GET_tags_id'}
	{'PATCH', '/tags/:id', './PATCH_tags_id'}
	{'DELETE', '/tags/:id', './DELETE_tags_id'}
	{'GET', '/tags/list', './GET_tags_list'} -- deprecated
	
	{'GET', '/albums', './GET_albums'}
	{'PUT', '/albums', './PUT_albums'}
	{'GET', '/albums/:id', './GET_albums_id'}
	{'PATCH', '/albums/:id', './PATCH_albums_id'}
	{'DELETE', '/albums/:id', './DELETE_albums_id'}
	
	{'PUT', '/upload', './PUT_upload'} -- not completely compliant yet
	-- {'POST', '/upload', './POST_upload'} -- important, but not implemented yet
	
	{'GET', '/images', './GET_images'}
	{'GET', '/images/:id', './GET_images_id'}
	{'PATCH', '/images/:id', './PATCH_images_id'}
	{'DELETE', '/images/:id', './DELETE_images_id'}
	{'GET', '/images/:id/raw', './GET_images_id_raw'}
	{'GET', '/images/public/:filename', './GET_images_public_filename'}
}

-- convert the routes to something more usable
routes={}
for r in *routelist
	route={
		regexp: "^"..(r[2]\gsub ":[^/]+", '([^/]+)').."/?$" -- convert :stuff to a regexp
		method: r[1]\upper!
		handler: require r[3] -- load the actual module
		params: {}
	}
	r[2]\gsub ":([^/]+)", (param) -> table.insert route.params, param -- re-add the params
	route.params=nil if #route.params==0 -- remove them again if they don't exist
	table.insert(routes, route)

-- sub function to apply parameters to a req object
applyparamsimp=(params, paramlist, ...) ->
	params[paramlist[i]]=select(i, ...) for i=1, select('#', ...)
	return params

-- apply the parameters to a req object
applyparams=(regexp, url, paramlist) -> applyparamsimp {}, paramlist, url\match regexp

(req, res, next, a) ->
	if 'string'==type req -- alternate operation: edit routes
		if 'add'==req -- add a route
			method, path, handler=res, next, a
			route={
				regexp: "^"..(path\gsub ":[^/]+", '([^/]+)').."/?$" -- convert :stuff to a regexp
				method: method\upper!
				handler: handler
				params: {}
			}
			path\gsub ":([^/]+)", (param) -> table.insert route.params, param -- re-add the params
			route.params=nil if #route.params==0 -- remove them again if they don't exist
			table.insert(routes, route)
		return
	
	-- make sure we should handle this
	return next! unless '/api'==req.url\sub 1, #'/api' 
	
	-- fetch data from the req object
	method=req.method\upper!
	url=(req.url\sub 1+#'/api')\gsub "%?.+$", ''
	
	-- find the correct route, if any
	for route in *routes
		if (route.method==method or route.method=='ALL') and url\match route.regexp
			-- apply the parameters, if applicable
			if route.params
				req.params=applyparams route.regexp, url, route.params
			
			-- run the handler
			ok, err=pcall route.handler, req, res, next
			unless ok
				return res\status(500)\json {:ok, :err}
			return
	
	-- we didn't find the route
	next!
