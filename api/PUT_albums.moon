db=require '../db'
authenticate=require './authenticate'
JSON=require 'JSON'

tagforname=db.Statement.get 'tag/forname'
tagidexists=db.TemplatedStatement.get 'tag/exists', {id: true}
imageidexists=db.TemplatedStatement.get 'image/exists', {id: true}
incrementalbumcount=db.TemplatedStatement.get 'tag/updatealbumcount', {id: true, mode: 'increment'}
incrementimagecount=db.TemplatedStatement.get 'album/updateimagecount', {id: true, mode: 'increment'}
albumaddtag=db.Statement.get 'album/addtag'
albumaddimage=db.Statement.get 'album/addimage'

(req, res) ->
	return unless authenticate req, res, {'write'}
	
	import name, description, nsfw, tags, images from req.body
	if description=='' or description==JSON.null
		description=nil
	
	tags={} if tags==nil
	images={} if images==nil
	
	if ('string'!=type name) or ('boolean'!=type nsfw) or (''==name) or ('table'!=type tags) or ('table'!=type images)
		return res\status(400)\json {ok: false, err: "Invalid parameter types"}
	
	db.begin 'write', (commit, rollback) ->
		-- decode tags
		ok, err=pcall () ->
			for i, tag in ipairs tags
				if 'string'==type tag
					ok, tags[i]=pcall tagforname\getsingle, {name: tag}
					error "Invalid tag name: #{tag} at index #{i-1}" unless ok
				elseif 'number'==type tag
					error "Invalid tag id: #{tag} at index #{i-1}" unless tagidexists\has {id: tag}
				else
					error "Invalid tag type: #{type tag} at index #{i-1}"
		unless ok
			rollback!
			return res\status(400)\json {:ok, :err}
		
		-- ensure images exist
		ok, err=pcall () ->
			for i, image in ipairs images
				if 'number'!=type image
					error "Invalid image type: #{type image} at index #{i-1}"
				elseif not imageidexists\has {id: image}
					error "Invalid image id: #{image} at index #{i-1}"
		unless ok
			rollback!
			return res\status(400)\json {:ok, :err}
		
		-- insert the actual album in the db
		ok, err=pcall db.TemplatedStatement.insert, 'album/create', {description: description and true}, {:name, :description, :nsfw}
		unless ok
			rollback!
			return res\status(500)\json {:ok, :err}
		id=err
		
		-- add the tags to the album
		ok, err=pcall () ->
			for tag in *tags
				albumaddtag\insert {:tag, album: id}
				incrementalbumcount\update {id: tag}
		unless ok
			rollback!
			return res\status(500)\json {:ok, :err}
		
		-- add the images to the album
		ok, err=pcall () ->
			for image in *images
				addalbumimage\insert {:image, album: id}
				incrementimagecount\update {:id}
		unless ok
			rollback!
			return res\status(500)\json {:ok, :err}
		
		-- we're done
		commit!
		return res\json {ok: true, res: {
				:id,
				:name,
				description: description or JSON.null,
				:nsfw,
				:images,
				:tags,
				imagecount: #images
			}}
