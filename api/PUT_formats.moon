db=require '../db'
authenticate=require './authenticate'

createformat=db.Statement.get 'format/create'

(req, res) ->
	return unless authenticate req, res, {'write'}
	import name, video from req.body
	if ('string'!=type name) or ('boolean'!=type video) or ''==name
		return res\status(400)\json {ok: false, err: "Invalid parameter types"}
	db.begin 'write', (commit, rollback) ->
		ok, val=pcall createformat\insert, {:name, :video}
		unless ok
			rollback!
			return res\status(409)\json {ok: false, err: "Conflicting format name"}
		commit!
		res\status(201)\json {:ok, res: {:name, :video, id: val}}
