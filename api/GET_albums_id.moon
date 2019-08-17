db=require '../db'
authenticate=require './authenticate'

-- read all required statements from disk
getalbum=db.Statement.get 'album/get'
getalbumimages=db.Statement.get 'album/getsubpartialimages'
getalbumtags=db.Statement.get 'album/getpartialtags'

-- convert SubPartialImage objects
subpartialimage=(row) ->
	row.nsfw=row.nsfw==1
	row.format={id: row.fid, name: row.fname, video: row.fvideo==1}
	row.fid, row.fname, row.fvideo=nil, nil, nil
	return row

-- convert PartialTag objects
partialtag=(row) ->
	row.nsfw=row.nsfw==1
	return row

-- convert Album objects
album=(row) ->
	row.nsfw=row.nsfw==1
	row.images=[subpartialimage image for image in getalbumimages\iterate {id: row.id}]
	row.tags=[partialtag tag for tag in getalbumtags\iterate {id: row.id}]
	return row

(req, res) ->
	return unless authenticate req, res, {'read'}
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	db.begin 'read', (done) ->
		ok, val=pcall getalbum\getrow, {:id}
		unless ok
			done!
			return res\status(404)\json {:ok, err: "Album #{id} not found"}
		ok, val=pcall album, val
		done!
		unless ok
			return res\status(500)\json {:ok, err: val}
		res\json {:ok, res: val}
