db=require '../db'
authenticate=require './authenticate'

getformat=db.Statement.get 'format/get'

(req, res) ->
	return unless authenticate req, res, {'read'}
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	db.begin 'read', (done) ->
		ok, val=pcall getformat\getrow, {:id}
		unless ok
			done!
			return res\status(404)\json {:ok, err: "Format #{id} not found"}
		done!
		res\json {:ok, res: {id: val.id, name: val.name, video: val.video==1}}
