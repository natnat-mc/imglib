db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'
getdiff=require '../libs/getdiff'
JSON=require 'JSON'

imageexists=db.TemplatedStatement.get 'image/exists', {id: true}
imageget=db.Statement.get 'image/get'
imagegettagids=db.Statement.get 'image/gettagids'
imagegetalbumids=db.Statement.get 'image/getalbumids'
imageaddtag=db.Statement.get 'image/addtag'
imageremovetag=db.Statement.get 'image/removetag'

tagexists=db.TemplatedStatement.get 'tag/exists', {id: true}
tagforname=db.Statement.get 'tag/forname'

albumexists=db.TemplatedStatement.get 'album/exists', {id: true}
albumforname=db.Statement.get 'album/forname'
albumaddimage=db.Statement.get 'album/addimage'
albumremoveimage=db.Statement.get 'album/removeimage'

local stage1, stage2, stage3

-- stage1: detect modifications
stage1=(req, res) ->
	id=tonumber req.params.id
	import name, description, nsfw, tags, albums from req.body
	
	local changename, removename, changedescription, removedescription, changensfw, changetags, changealbums
	
	db.begin 'read', (done) ->
		unless imageexists\has {:id}
			done!
			return res\status(404)\json {ok: false, err: "Image #{id} not found"}
		
		ok, err=pcall () ->
			if name==JSON.null or name==''
				removename=true
			elseif 'string'==type name
				changename=true
			elseif name!=nil
				error "Invalid type for name: #{type name}"
			
			if description==JSON.null or description==''
				removedescription=true
			elseif 'string'==type description
				changedescription=true
			elseif description!=nil
				error "Invalid type for description: #{type description}"
			
			if 'boolean'==type nsfw
				changensfw=true
			elseif nsfw!=nil
				error "Invalid type for nsfw: #{type nsfw}"
			
			if 'table'==type tags
				changetags=true
				for i=1, #tags
					tag=tags[i]
					tagi=tonumber tag
					if tagi
						unless tagexists\has {id: tagi}
							error "Tag ID #{tagi} not found"
						tags[i]=tagi
					elseif 'string'==type tag
						ok, tags[i]=pcall tagforname\getsingle, {name: tag}
						unless ok
							error "Tag #{tag} not found"
					else
						error "Invalid type for tag: #{type tag}"
			elseif tags!=nil
				error "Invalid type for tags: #{type tags}"
			
			if 'table'==type albums
				changealbums=true
				for i=1, #albums
					album=albums[i]
					albumi=tonumber album
					if albumi
						unless albumexists\has {id: albumi}
							error "Album ID #{albumi} not found"
						albums[i]=albumi
					elseif 'string'==type album
						ok, albums[i]=pcall albumforname\getsingle, {name: album}
						unless ok
							error "Album #{album} not found"
					else
						error "Invalid type for album: #{type album}"
			elseif albums!=nil
				error "Invalid type for albums: #{type albums}"
		
		unless ok
			done!
			return res\status(400)\json {:ok, :err}
		
		ok, err=pcall () ->
			tags=tags or [tag for {:tag} in imagegettagids\iterate {:id}]
			albums=albums or [album for {:album} in imagegetalbumids\iterate {:id}]
		unless ok
			done!
			return res\status(500)\json {:ok, err: "Failed to read old tags and albums"}
		
		data={
			:id, :name, :description, :nsfw, :tags, :albums
			:changename, :removename, :changedescription, :removedescription, :changensfw, :changetags, :changealbums
		}
		
		if changetags or changealbums
			return stage2 req, res, data, done
		else
			done!
			return stage3 req, res, data

-- stage2: compute tag and album diff
stage2=(req, res, data, done) ->
	local oldtags, oldalbums
	
	if changetags
		ok, err=pcall () ->
			oldtags=[tag for {:tag} in imagegettagids\iterate {id: data.id}]
		unless ok
			done!
			return res\status(500)\json {:ok, err: "Couldn't read old tags: #{err}"}
		data.removedtags, data.addedtags=getdiff oldtags, data.tags
	
	if changealbums
		ok, err=pcall () ->
			oldalbums=[album for {:album} in imagegetalbumids\iterate {id: data.id}]
		unless ok
			done!
			return res\status(500)\json {:ok, err: "Couldn't read old albums: #{err}"}
		data.removedalbums, data.addedalbums=getdiff oldalbums, data.albums
	
	done!
	return stage3 req, res, data

-- stage3: apply modifications
stage3=(req, res, data) ->
	db.begin 'write', (commit, rollback) ->
		ok, err=pcall () ->
			params={
				changename: data.changename, removename: data.removename
				changedescription: data.changedescription, removedescription: data.removedescription
				changensfw: data.changensfw
			}
			vals={
				name: data.name, description: data.description, nsfw: data.nsfw, id: data.id
			}
			db.TemplatedStatement.update 'image/patch', params, vals
		unless ok
			rollback!
			return res\status(500)\json {:ok, err: "Failed to edit core resource: #{err}"}
		
		if changetags
			ok, err=pcall () ->
				for tag in *data.removedtags
					imageremovetag\execute {image: data.id, :tag}
				for tag in *data.addedtags
					imageaddtag\insert {image: data.id, :tag}
			unless ok
				rollback!
				return res\status(500)\json {:ok, err: "Failed to update tags: #{err}"}
		
		if changealbums
			ok, err=pcall () ->
				for album in *data.removedalbums
					albumremoveimage\execute {image: data.id, :album}
				for album in *data.addedalbums
					albumaddimage\insert {image: data.id, :album}
			unless ok
				rolback!
				return res\status(500)\json {:ok, err: "Failed to update albums: #{err}"}
		
		image=imageget\getrow {id: data.id}
		commit!
		res\json {
			ok: true
			res: {
				id: data.id
				name: image.name or JSON.null
				description: image.description or JSON.null
				nsfw: image.nsfw==1
				width: image.width
				height: image.height
				format: {
					id: image.fid
					name: image.fname
					video: image.fvideo
				}
				adddate: image.adddate
				checksum: image.checksum
				albums: data.albums
				tags: data.tags
			}
		}

(req, res) ->
	return unless authenticate req, res, {'write'}
	stage1 req, res
