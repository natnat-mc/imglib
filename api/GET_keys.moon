auth=require './auth'
authenticate=require './authenticate'
db=require '../db'

(req, res) ->
	return unless authenticate req, res, {'api'}
	
	db.begin 'write', (commit, rollback) ->
		if pcall auth.cleanup
			commit!
		else
			rollback!
		
		db.begin 'read', (done) ->
			ok, keys=pcall auth.getkeys
			unless keys
				done!
				return res\status(500)\json {:ok, err: keys}
			
			done!
			res\json {:ok, res: keys}
