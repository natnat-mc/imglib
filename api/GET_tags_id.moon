db=require '../db'
authenticate=require './authenticate'

gettag=db.Statement.get 'tag/get'

(req, res) ->
	return unless authenticate req, res, {'read'}
	
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	
	db.begin 'read', (done) ->
		ok, val=pcall gettag\getrow, {:id}
		unless ok
			done!
			return res\status(404)\json {:ok, err: "Tag #{id} not found"}
		
		done!
		res\json {:ok, res: {id: val.id, name: val.name, description: val.description, color: val.color, nsfw: val.nsfw==1, imagecount: val.imagecount, albumcount: val.albumcount}}
