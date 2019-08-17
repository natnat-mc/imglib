db=require '../db'
authenticate=require './authenticate'

getimage=db.Statement.get 'image/get'
getimagealbums=db.Statement.get 'image/getalbums'
getimagetags=db.Statement.get 'image/gettags'

-- SubPartialAlbum converter
subpartialalbum=(row) ->
	row.nsfw=row.nsfw==1
	return row

-- PartialTag converter
partialtag=(row) ->
	row.nsfw=row.nsfw==1
	return row

-- Image converter
image=(row) ->
	row.nsfw=row.nsfw==1
	row.format={id: row.fid, name: row.fname, video: row.fvideo==1}
	row.fid, row.fname, row.fvideo=nil, nil, nil
	row.tags=[partialtag row for row in getimagetags\iterate {id: row.id}]
	row.albums=[subpartialalbum row for row in getimagealbums\iterate {id: row.id}]
	return row

(req, res) ->
	return unless authenticate req, res, {'read'}
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	db.begin 'read', (done) ->
		ok, val=pcall getimage\getrow, {:id}
		unless ok
			done!
			return res\status(404)\json {:ok, err: "Image #{id} not found"}
		ok, val=pcall image, val
		done!
		unless ok
			return res\status(500)\json {:ok, err: val}
		res\json {:ok, res: val}
