db=require '../db'
authenticate=require './authenticate'
config=require '../app/config'

imagegetformat=db.Statement.get 'image/getformat'
formatgetmimetype=db.Statement.get 'format/getmimetype'

(req, res) ->
	return unless authenticate req, res, {'read'}
	
	db.begin 'read', (done) ->
		id=req.params.id
		ok, format=pcall imagegetformat\getsingle, {:id}
		unless ok
			done!
			return res\status(404)\json {:ok, err: "Image not found"}
		
		done!
		res\sendFile "#{config.data.images}/#{id}.#{format}", {"Content-Type": formatgetmimetype\getsingle {name: format}}
