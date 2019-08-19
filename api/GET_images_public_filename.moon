config=require '../app/config'
db=require '../db'

checkvalidimage=db.Statement.get 'image/checkvalid'
formatgetmimetype=db.Statement.get 'format/getmimetype'

(req, res) ->
	return unless authenticate req, res, {}
	
	id, format=req.params.filename\match "^(%d+)%.(%S+)$"
	checksum=req.query.checksum
	
	db.begin 'read', (done) ->
		if checkvalidimage\has {:id, :format, :checksum}
			res\sendFile "#{config.data.images}/#{id}.#{format}", {"Content-Type": formatgetmimetype\getsingle {name: format}}
			done!
		else
			res\status(404)\send "Image or video not found"
			done!
