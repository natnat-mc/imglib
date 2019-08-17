db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'
JSON=require 'JSON'

gettag=db.Statement.get 'tag/get'

(req, res) ->
	return unless authenticate req, res, {'write'}
	id=tonumber req.params.id
	import description, color from req.body
	
	removedescription=description==JSON.null or description==''
	description=nil if removedescription
	changecolor=color!=nil
	changedescription=description!=nil
	
	return res\status(400)\json {ok: false, err: "Invalid color"} unless pcall getquery, color, 'string:color', true
	return res\status(400)\json {ok: false, err: "Invalid description"} unless pcall getquery, description, 'string', true
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	
	db.begin 'write', (commit, rollback) ->
		unless db.TemplatedStatement.has 'tag/exists', {id: true}, {:id}
			rollback!
			return res\status(404)\json {ok: false, err: "Tag #{id} not found"}
		
		ok, patchtag=pcall db.TemplatedStatement.get, 'tag/patch', {:removedescription, :changecolor, :changedescription}
		unless ok
			rollback!
			return res\status(400)\json {:ok, err: patchtag}
		
		ok, err=pcall patchtag\update, {:id, :color, :description}
		unless ok
			rollback!
			return res\status(500)\json {:ok, :err}
		
		ok, val=pcall gettag\getrow, {:id}
		unless ok
			rollback!
			return res\status(500)\json {:ok, err: "Unable to edit tag: #{val}"}
		
		commit!
		val.nsfw=val.nsfw==1
		res\json {:ok, res: val}
