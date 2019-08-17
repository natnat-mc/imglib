db=require '../db'
authenticate=require './authenticate'
JSON=require 'JSON'


(req, res) ->
	return unless authenticate req, res, {'write'}
	
	import name, description, color, nsfw from req.body
	if description=='' or description==JSON.null
		description=nil
		
	if ('string'!=type name) or ('boolean'!=type nsfw) or ''==name or ('string'!=type color) or not (#color==6 and color\match "^[0-9a-fA-F]+$")
		return res\status(400)\json {ok: false, err: "Invalid parameter types"}
	
	db.begin 'write', (commit, rollback) ->
		if db.TemplatedStatement.has 'tag/exists', {name: true}, {:name}
			rollback!
			return res\status(409)\json {ok: false, err: "Conflicting tag name"}
		
		ok, val=pcall db.TemplatedStatement.insert 'tag/create', {description: description and true or false}, {:name, :description, :color, :nsfw}
		unless ok
			rollback!
			return res\status(500)\json {ok: false, err: "Unable to create tag: #{val}"}
		
		commit!
		res\status(201)\json {:ok, res: {:name, :description, id: val, :color, :nsfw, imagecount: 0, albumcount: 0}}
