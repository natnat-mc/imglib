db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'
fs=require 'fs'
config=require '../app/config'

tagforname=db.Statement.get 'tag/forname'
tagidexists=db.TemplatedStatement.get 'tag/exists', {id: true}
albumforname=db.Statement.get 'album/forname'
albumidexists=db.TemplatedStatement.get 'album/exists', {id: true}
formatforname=db.Statement.get 'format/forname'
getformat=db.Statement.get 'format/get'
imageaddtag=db.Statement.get 'image/addtag'
albumaddimage=db.Statement.get 'album/addimage'
imagegetadddate=db.Statement.get 'image/getadddate'

imageinfo=require '../libs/imageinfo'

(req, res) ->
	return unless authenticate req, res, {'upload'}
	-- `curl -X PUT --data-binary '@'<path> -H "Content-Type: image/png" <url>?<params>`
	
	-- adddate is now
	adddate=os.time!
	
	-- read query arguments
	import tags, albums, name, description, nsfw, format from req.query
	ok, err=pcall () ->
		tags=getquery tags, 'list'
		albums=getquery albums, 'list'
		name=getquery name, 'string', true
		description=getquery description, 'string', true
		nsfw=getquery nsfw, 'boolean'
		ok, fmt=pcall getquery, format, 'int'
		if ok
			format=fmt
		else
			format=getquery format, 'string'
	unless ok
		return res\status(400)\json {:ok, :err}
	
	-- decode tags, albums and format
	db.begin 'read', (done) ->
		ok, err=pcall () ->
			-- decode tags
			for i=1, #tags do
				id=tonumber tags[i]
				if id
					error "Tag ID not found: #{id}" unless tagidexists\has {:id}
				else
					ok, id=pcall tagforname\getsingle, {name: tags[i]}
					error "Tag not found: #{tags[i]}" unless ok
				tags[i]=id
			
			-- decode albums
			for i=1, #albums do
				id=tonumber albums[i]
				if id
					error "Album ID not found: #{id}" unless albumidexists\has {:id}
				else
					ok, id=pcall albumforname\getsingle, {name: albums[i]}
					error "Album not found: #{albums[i]}" unless ok
				albums[i]=id
			
			-- decode format
			do
				id=tonumber format
				unless id
					ok, id=pcall formatforname\getsingle, {name: format}
					error "Format not found: #{format}" unless ok
				ok, format=pcall getformat\getrow, {:id}
				error "Format ID not found: #{id}" unless ok
				format.video=format.video==1
		unless ok
			done!
			return res\status(400)\json {:ok, :err}
		
		done!
		
		filename=os.tmpname!
		fs.writeFile filename, req.body, (err) ->
			return res\status(500)\json {ok: false, :err} if err
			
			info=imageinfo filename
			fs.unlink filename, () -> nil
			if (format.video and 'video' or 'image')!=info.kind or format.name!=info.format
				return res\status(400)\json {ok: false, err: "Requested format was #{format.video and 'video' or 'image'}/#{format.name} but file was #{info.kind}/#{info.format}"}
			
			db.begin 'write', (commit, rollback) ->
				ok, id=pcall db.TemplatedStatement.insert, 'image/create', {name: name and true, description: description and true}, {:name, :description, :nsfw, width: info.width, height: info.height, format: format.id, checksum: info.hash, :adddate}
				unless ok
					rollback!
					return res\status(500)\json {:ok, :err}
				
				ok, err=pcall () ->
					for tag in *tags
						imageaddtag\insert {image: id, :tag}
					for album in *albums
						albumaddimage\insert {image: id, :album}
				unless ok
					rollback!
					return res\status(500)\json {:ok, :err}
				
				filename="#{config.data.images}/#{id}.#{format.name}"
				fs.writeFile filename, req.body, (err) ->
					if err
						rollback!
						return res\status(500)\json {ok: false, :err}
					
					commit!
					res\json {ok: true, res: {:id, :name, :description, :nsfw, width: info.width, height: info.height, :format, :adddate, checksum: info.hash, :albums, :tags}}
