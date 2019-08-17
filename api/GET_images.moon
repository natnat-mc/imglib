db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'

albumexists=db.TemplatedStatement.get 'album/exists', {id: true}
tagforname=db.Statement.get 'tag/forname'
tagidexists=db.TemplatedStatement.get 'tag/exists', {id: true}
clearyestags=db.Statement.get 'tagcombo/clearyes'
addyestag=db.Statement.get 'tagcombo/addyes'
clearnotags=db.Statement.get 'tagcombo/clearno'
addnotag=db.Statement.get 'tagcombo/addno'
clearanytags=db.Statement.get 'tagcombo/clearany'
addanytag=db.Statement.get 'tagcombo/addany'
getimagetags=db.Statement.get 'image/gettags'
getimagealbums=db.Statement.get 'image/getalbums'

-- subpartialalbum converter
subpartialalbum=(row) ->
	row.nsfw=row.nsfw==1
	return row

-- partialtag converter
subpartialtag=(row) ->
	row.nsfw=row.nsfw==1
	return row

-- partialimage converter
partialimage=(row) ->
	row.nsfw=row.nsfw==1
	row.format={id: row.fid, name: row.fname, video: row.fvideo==1}
	row.fid, row.fname, row.fvideo=nil, nil, nil
	row.tags=[subpartialtag row for row in getimagetags\iterate {id: row.id}]
	row.albums=[subpartialalbum row for row in getimagealbums\iterate {id: row.id}]
	return row

-- tag validator
validatetag=(tag) ->
	tagn=tonumber(tag)
	if tagn
		if tagidexists\has {id: tagn}
			return tagn
		error "Tag ID #{tagn} not found"
	elseif 'string'==type tag
		ok, id=pcall tagforname\getsingle, {name: tag}
		error "Tag #{tag} not found" unless ok
		return id
	else
		error "Tag must be specified as a string or int"
validatetags=(list) -> [validatetag tag for tag in *list]

-- load all tags into request
loadtags=(vals, yestags, notags, anytags, fn) ->
	-- function to actually do it
	loadall=() ->
		if yestags
			if #yestags<=100
				vals["yestag#{i}"]=tag for i, tag in ipairs yestags
			else
				clearyestags\execute!
				addyestag\insert {:id} for id in *yestags
		if notags
			if #notags<=100
				vals["notag#{i}"]=tag for i, tag in ipairs notags
			else
				clearnotags\execute!
				addnotag\insert {:id} for id in *notags
		if anytags
			if #anytags<=100
				vals["anytag#{i}"]=tag for i, tag in ipairs anytags
			else
				clearanytags\execute!
				addanytag\insert {:id} for id in *anytags
	
	-- transaction wrapper
	if (yestags and #yestags>100) or (notags and #notags>100) or (anytags and #anytags>100)
		db.begin 'write', (commit, rollback) ->
			ok, err=pcall loadall
			if ok
				commit!
				fn!
			else
				rollback!
				fn err
	else
		loadall!
		fn!

(req, res) ->
	return unless authenticate req, res, {'read'}
	
	-- read query parameters
	import yestags, notags, anytags, album, q, name, nsfw, kind, before, after from req.query
	local video
	ok, err=pcall () ->
		yestags=getquery yestags, 'list', true
		notags=getquery notags, 'list', true
		anytags=getquery anytags, 'list', true
		album=getquery album, 'int', true
		q=getquery q, 'string', true
		name=getquery name, 'string', true
		nsfw=getquery nsfw, 'boolean|\'any\'', true
		nsfw=nil if nsfw=='any'
		kind=getquery kind, 'string', true
		error "Kind must be 'image', 'video' or 'any'" if kind!=nil and kind!='image' and kind!='video' and kind!='any'
		kind=nil if kind=='any'
		video=true if kind=='video'
		video=false if kind=='image'
		kind=nil
		before=getquery before, 'int', true
		after=getquery after, 'int', true
	unless ok
		return res\status(400)\json {:ok, :err}
	
	-- validate and decode parameters
	db.begin 'read', (done) ->
		if yestags
			ok, yestags=pcall validatetags, yestags
			unless ok
				done!
				return res\status(400)\json {:ok, err: "Error while validating yestags: #{yestags}"}
		if notags
			ok, notags=pcall validatetags, notags
			unless ok
				done!
				return res\status(400)\json {:ok, err: "Error while validating notags: #{notags}"}
		if anytags
			ok, anytags=pcall validatetags, anytags
			unless ok
				done!
				return res\status(400)\json {:ok, err: "Error while validating anytags: #{anytags}"}
		if album
			unless albumexists\has {id: album}
				done!
				return res\status(400)\json {ok: false, err: "Album ID #{album} not found"}
		done!
		
		-- create statement parameters
		params={
			q: q and true,
			name: name and true,
			nsfw: nsfw!=nil or nil,
			before: before and true,
			after: after and true,
			video: video!=nil or nil,
			album: album and true,
			yestags: yestags and #yestags<=100 and #yestags or yestags!=nil or nil,
			notags: notags and #notags<=100 and #notags or notags!=nil or nil,
			anytags: anytags and #anytags<=100 and #anytags or anytags!=nil or nil
		}
		
		-- create statement arguments
		vals={
			:q,
			:name,
			:nsfw,
			:video,
			:before,
			:after,
			:album
		}
		
		-- load all yes/no/any tags
		loadtags vals, yestags, notags, anytags, (err) ->
			-- we do have a race condition between stages 1 and 2 if another read is already pending and a write is buffered, but it can only be an issue if the selected tags are deleted and can't crash the request
			-- the transition between stages 2 and 3 is guaranteed to be undisrupted, because no write can be queued between them (stage 2 calls stage 3 synchronously and is synchronous itself, also being called synchronously by stage 1)
			-- also, stage 2 only writes to db if more than 100 tags are selected for a category
			if err
				return res\status(500)\json {ok: false, :err}
			
			-- actually run the request
			db.begin 'read', (done) ->
				listimages=db.TemplatedStatement.get 'image/list', params
				res\streamStatement listimages, vals, partialimage, done
