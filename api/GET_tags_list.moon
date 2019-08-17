db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'

gettag=db.Statement.get 'tag/get'

(req, res) ->
	return unless authenticate req, res, {'read'}
	ok, val=pcall getquery, req.query.id, 'list'
	return res\status(400)\json {:ok, err: val} unless ok
	return res\status(400)\json {ok: false, err: "Too many ids, maximum is 50; got #{#val}"} if #val>50
	ret, i={}, 1
	db.begin 'read', (done) ->
		for id in *val
			unless tonumber id
				done!
				return res\status(400)\json {ok: false, err: "Invalid id #{id}"} 
			ok, row=pcall gettag\getrow, {:id}
			unless ok
				done!
				return res\status(404)\json {:ok, err: "Tag #{id} not found"}
			ret[i], i={id:row.id, name:row.name, description:row.description, color:row.color, nsfw:row.nsfw==1, imagecount:row.imagecount, albumcount:row.albumcount}, i+1
		done!
		res\json {:ok, res:ret}
