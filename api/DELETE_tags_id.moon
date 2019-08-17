db=require '../db'
authenticate=require './authenticate'

deletetag=db.Statement.get 'tag/delete'

(req, res) ->
	return unless authenticate req, res, {'write'}
	
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	
	db.begin 'write', (commit, rollback) ->
		unless db.TemplatedStatement.has 'tag/exists', {id: true}, {:id}
			rollback!
			return res\status(404)\json {ok: false, err: "Tag #{id} not found"}
		
		ok, err=pcall deletetag\execute, {:id}
		unless ok
			rollback!
			return res\status(500)\json {:ok, err: "Failed to delete tag: #{err}"}
		
		commit!
		res\json {:ok}
