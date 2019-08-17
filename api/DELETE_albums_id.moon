db=require '../db'
authenticate=require './authenticate'

decrementalbumcount=db.TemplatedStatement.get 'tag/updatealbumcount', {id: true, mode: 'decrement'}
albumgettags=db.Statement.get 'album/gettags'
albumdelete=db.Statement.get 'album/delete'
albumexists=db.TemplatedStatement.get 'album/exists', {id: true}

(req, res) ->
	return unless authenticate req, res, {'write'}
	id=tonumber req.params.id
	return res\status(400)\json {ok: false, err: "Invalid id #{req.params.id}"} unless id
	db.begin 'read', (done) ->
		unless albumexists\has {:id}
			done!
			return res\status(404)\json {ok: false, err: "Album #{id} not found"}
		done!
		db.begin 'write', (commit, rollback) ->
			ok, err=pcall () ->
				decrementalbumcount\update {id: tag} for {:tag} in albumgettags\iterate {:id}
				albumdelete\execute, {:id}
			unless ok
				rollback!
				return res\status(404)\json {:ok, err: "Failed to delete album: #{err}"}
			commit!
			res\json {:ok}
