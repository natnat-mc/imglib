db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'

-- read all required statements from disk
getalbumimages=db.Statement.get 'album/getsubpartialimages'
getalbumtags=db.Statement.get 'album/getpartialtags'
tagforname=db.Statement.get 'tag/forname'
clearyestags=db.Statement.get 'tagcombo/clearyes'
addyestag=db.Statement.get 'tagcombo/addyes'
clearnotags=db.Statement.get 'tagcombo/clearno'
addnotag=db.Statement.get 'tagcombo/addno'
clearanytags=db.Statement.get 'tagcombo/clearany'
addanytag=db.Statement.get 'tagcombo/addany'

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

-- convert PartialAlbum objects
partialalbum=(row) ->
	row.nsfw=row.nsfw==1
	row.images=[subpartialimage image for image in getalbumimages\iterate {id: row.id}]
	row.tags=[partialtag tag for tag in getalbumtags\iterate {id: row.id}]
	return row

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
	
	-- read and validate query
	import q, name, nsfw, minimagecount, maximagecount, yestags, notags, anytags from req.query
	ok, err=pcall () ->
		q=getquery q, 'string', true
		name=getquery name, 'string', true
		nsfw=getquery nsfw, 'boolean|\'any\'', true
		nsfw=nil if nsfw=='any'
		minimagecount=getquery minimagecount, 'int', true
		maximagecount=getquery maximagecount, 'int', true
		yestags=getquery yestags, 'list', true
		notags=getquery notags, 'list', true
		anytags=getquery anytags, 'list', true
		error "invalid image count boundaires" if minimagecount and maximagecount and maximagecount<minimagecount
	return res\status(400)\json {:ok, :err} unless ok
	
	-- read all tag names
	db.begin 'read', (done) ->
		ok, err=pcall () ->
			if yestags
				yestags=[(tonumber tag) or tagforname\getsingle {name: tag} for tag in *yestags]
			if notags
				notags=[(tonumber tag) or tagforname\getsingle {name: tag} for tag in *notags]
			if anytags
				anytags=[(tonumber tag) or tagforname\getsingle {name: tag} for tag in *anytags]
		done!
		return res\status(400)\json {:ok, err: "Unable to retrieve all tags: #{err}"} unless ok
		
		-- create statement parameters
		params={
			q: q and true,
			name: name and true,
			nsfw: nsfw!=nil or nil,
			minimagecount: minimagecount and true,
			maximagecount: maximagecount and true,
			yestags: yestags and #yestags<=100 and #yestags or yestags!=nil or nil,
			notags: notags and #notags<=100 and #notags or notags!=nil or nil,
			anytags: anytags and #anytags<=100 and #anytags or anytags!=nil or nil
		}
		
		-- create statement arguments
		vals={
			:q,
			:name,
			:nsfw,
			:minimagecount,
			:maximagecount,
			:minalbumcount
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
				listalbums=db.TemplatedStatement.get 'album/list', params
				res\streamStatement listalbums, vals, partialalbum, done
