db=require '../db'
auth=require './auth'
authenticate=require './authenticate'

(req, res) ->
	return unless authenticate req, res, {'api'}
	
	id=tonumber req.params.id
	unless id
		return res\status(400)\json {ok: false, err: "Invalid ID"}
	
	db.begin 'write', (commit, rollback) ->
		if pcall auth.cleanup
			commit!
		else
			rollback!
		
		db.begin 'write', (commit, rollback) ->
			unless auth.keyidexists id
				rollback!
				return res\status(404)\json {ok: false, "Key #{id} not found"}
			
			ok, err=pcall auth.deletekey, id
			unless ok
				rollback!
				return res\status(500)\json {:ok, :err}
			
			commit!
			res\json {:ok}
