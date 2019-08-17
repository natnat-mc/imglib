db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'

getformat=db.Statement.get 'format/get'

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
			ok, row=pcall getformat\getrow, {:id}
			unless ok
				done!
				return res\status(404)\json {:ok, err: "Format #{id} not found"}
			ret[i], i={id:row.id, name:row.name, video:row.video==1}, i+1
		done!
		res\json {:ok, res:ret}
