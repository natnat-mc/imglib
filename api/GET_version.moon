import appname, version, commit, branch from require '../app/appinfo'
authenticate=require './authenticate'

(req, res) ->
	return unless authenticate req, res, {}
	res\json {ok: true, res: {:appname, :version, :commit, :branch}}
