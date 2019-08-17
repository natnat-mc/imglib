db=require '../db'
authenticate=require './authenticate'

deleteformat=db.Statement.get 'format/delete'

(req, res) ->
	return unless authenticate req, res, {'write'}
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	db.begin 'write', (commit, rollback) ->
		ok=pcall deleteformat\execute, {:id}
		unless ok
			rollback!
			return res\status(404)\json {:ok, err: "Format #{id} not found"} unless ok
		commit!
		res\json {:ok}
