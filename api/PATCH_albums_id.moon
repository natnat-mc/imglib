db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'
getdiff=require '../libs/getdiff'
JSON=require 'JSON'

tagforname=db.Statement.get 'tag/forname'
tagidexists=db.TemplatedStatement.get 'tag/exists', {id: true}
imageidexists=db.TemplatedStatement.get 'image/exists', {id: true}
incrementalbumcount=db.TemplatedStatement.get 'tag/updatealbumcount', {id: true, mode: 'increment'}
incrementimagecount=db.TemplatedStatement.get 'album/updateimagecount', {id: true, mode: 'increment'}
decrementalbumcount=db.TemplatedStatement.get 'tag/updatealbumcount', {id: true, mode: 'decrement'}
decrementimagecount=db.TemplatedStatement.get 'album/updateimagecount', {id: true, mode: 'decrement'}
albumaddtag=db.Statement.get 'album/addtag'
albumaddimage=db.Statement.get 'album/addimage'
albumremovetag=db.Statement.get 'album/removetag'
albumremoveimage=db.Statement.get 'album/removeimage'
albumgettags=db.Statement.get 'album/gettags'
albumgetimages=db.Statement.get 'album/getimages'
albumget=db.Statement.get 'album/get'

-- stage 3: apply modifications
stage3=(req, res, data) ->
	db.begin 'write', (commit, rollback) ->
		-- unpack all the data we have gathered
		import changename, changedescription, removedescription, changensfw, name, description, nsfw, tags, images, id, removedtags, addedtags, removedimages, addedimages from data
		local imagecount
		
		ok, err=pcall () ->
			
			-- edit the core resource if needed
			if changename or changedescription or changensfw or removedescription
				ok, err=pcall db.TemplatedStatement.update, 'album/patch', {:changename, :changedescription, :changensfw, :removedescription}, {:name, :description, :nsfw}
				error "Failed to patch the main resource: #{err}" unless ok
			
			-- edit the tags
			for tag in *removedtags
				ok, err=pcall () ->
					albumremovetag\exec {album: id, :tag}
					decrementalbumcount\update {id: tag}
				error "Failed to remove tag #{tag}" unless ok
			for tag in *addedtags
				ok, err=pcall () ->
					albumaddtag\exec {album: id, :tag}
					incrementalbumcount\update {id: tag}
				error "Failed to add tag #{tag}" unless ok
			
			-- edit the images
			for image in *removedimages
				ok, err=pcall () ->
					albumremoveimage\exec {album: id, :image}
					decrementimagecount\update {:id}
				error "Failed to remove image #{id}" unless ok
			for image in *addedimages
				ok, err=pcall () ->
					albumaddimage\exec {album: id, :image}
					incrementimagecount\update {:id}
				error "Failed to add image #{id}" unless ok
			
			-- get the resulting album
			ok, err=pcall () ->
				import id, name, description, nsfw, imagecount from albumget\getrow {:id}
			error "Failed to read resulting album" unless ok
		
		-- handle errors correctly
		unless ok
			res\status(500)\json {:ok, :err}
			error err -- bubble the error, this will automatically rollback the transaction and write it to the logs
		
		-- everything worked, return the DirectAlbum
		commit!
		res\json {:ok, res: {:id, :name, :description, :nsfw, :images, :tags, :imagecount}}

-- stage 2: decode image and tag lists
stage2=(req, res, data) ->
	db.begin 'read', (done) ->
		ok, err=pcall () ->
			if 'table'==type data.tags
				-- decode all effective tags
				newtags={}
				for tag in *data.tags
					if 'string'==type tag
						ok, id=pcall tagforname\getsingle, {name: tag}
						unless ok
							error "Tag name not found: #{tag}"
						table.insert newtags, id
					elseif 'number'==type tag
						unless tagidexists\has {id: tag}
							error "Tag id not found: #{tag}"
						table.insert newtags, tag
					else
						error "Tag must be string or int, not #{type tag}"
				table.sort newtags
				
				-- read all old tags
				oldtags={row.tag for row in albumgettags\iterate {album: data.id}}
				table.sort oldtags
				
				-- get the tag diff
				data.removedtags, data.addedtags=getdiff oldtags, newtags
				data.tags=newtags
			elseif nil==data.tags
				data.removedtags, data.addedtags={}, {}
				data.tags={row.tag for row in albumgettags\iterate {album: data.id}}
			else
				error "Tag list must be a list"
			
			if 'table'==type data.images
				-- check all new images
				for image in *data.images
					if 'number'==type image
						unless imageidexists {id: image}
							error "Image id not found: #{image}"
					else
						error "Image must be int, not #{type image}"
				newimages=data.images
				table.sort newimages
				
				-- read all old images
				oldimages={row.image for row in albumgetimages\iterate {album: data.id}}
				table.sort oldimages
				
				-- get the image diff
				data.removedimages, data.addedimages=getdiff oldimages, newimages
			elseif nil==data.images
				data.removedimages, data.addedimages={}, {}
				data.images={row.image for row in albumgetimages\iterate {album: data.id}}
			else
				error "Image list must be a list"
			
			-- jump to stage 3
			done!
			stage3 req, res, data
		unless ok
			res\status(400)\json {:ok, :err}
			error err

-- stage 1: detect basic modifications
(req, res) ->
	return unless authenticate req, res, {'write'}
	id=tonumber req.params.id
	
	import name, description, nsfw, tags, images from req.body
	changename, changedescription, removedescription, changensfw=nil
	
	ok, err=pcall () ->
		error "Invalid value for name" unless name==nil or (''!=name and 'string'==type name)
		if name
			changename=true
		
		error "Invalid value for desc" unless description==JSON.null or description==nil or 'string'==type description
		if description=='' or description==JSON.null
			removedescription=true
			description=nil
		else
			changedescription=true
		
		error "Invalid nsfw flag" unless nsfw==nil or ('boolean'==type nsfw)
		if nsfw!=nil
			changensfw=true
	unless ok
		return res\status(400)\json {:ok, :err}
	
	-- jump to stage 2
	stage2 req, res, {:changename, :changedescription, :removedescription, :changensfw, :name, :description, :nsfw, :tags, :images, :id}
