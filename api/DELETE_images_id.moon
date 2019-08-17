db=require '../db'
authenticate=require './authenticate'
fs=require 'fs'
config=require '../app/config'

imageexists=db.TemplatedStatement.get 'image/exists', {id: true}
imagegetalbumids=db.Statement.get 'image/getalbumids'
imagegettagids=db.Statement.get 'image/gettagids'
imagegetformat=db.Statement.get 'image/getformat'
imagedelete=db.Statement.get 'image/delete'
decrementalbumimagecount=db.TemplatedStatement.get 'album/updateimagecount', {id: true, mode: 'decrement'}
decrementtagimagecount=db.TemplatedStatement.get 'tag/updateimagecount', {id: true, mode: 'decrement'}

(req, res) ->
	return unless authenticate req, res, {'write'}
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	db.begin 'read', (done) ->
		unless imageexists\has {:id}
			done!
			return res\status(404)\json {ok: false, err: "Image #{id} not found"}
		
		local albums, tags
		
		ok, err=pcall () ->
			albums=[album for {:album} in imagegetalbumids\iterate {:id}]
		unless ok
			done!
			return res\status(500)\json {:ok, err: "Unable to get albums for image"}
		
		ok, err=pcall () ->
			tags=[tag for {:tag} in imagegettagids\iterate {:id}]
		unless ok
			done!
			return res\status(500)\json {:ok, err: "Unable to get tags for image"}
		
		ok, format=pcall imagegetformat\getsingle, {:id}
		unless ok
			done!
			return res\status(500)\json {:ok, err: "Unable to find image format"}
		filename="#{config.data.images}/#{id}.#{format}"
		
		done!
		db.begin 'write', (commit, rollback) ->
			ok, err=pcall () ->
				for album in *albums
					decrementalbumimagecount\update {id: album}
			unless ok
				rollback!
				return res\status(500)\json {:ok, err: "Unable to update albums"}
			
			ok, err=pcall () ->
				for tag in *tags
					decrementtagimagecount\update {id: tag}
			unless ok
				rollback!
				return res\status(500)\json {:ok, err: "Unable to update tags"}
			
			ok, err=pcall imagedelete\execute, {:id}
			unless ok
				rollback!
				return res\status(500)\json {:ok, err: "Unable to delete image from database"}
			
			fs.unlink filename, (err) ->
				if err
					rollback!
					return res\status(500)\json {ok: false, err: "Unable to delete image file"}
				
				commit!
				res\json {ok: true}
