authenticate=require './authenticate'
auth=require './auth'
getquery=require './getquery'
db=require '../db'

(req, res) ->
	return unless authenticate req, res, {}
	
	import password, name, permissions, expires from req.body
	ok, err=pcall () ->
		password=getquery password, 'string'
		name=getquery name, 'string'
		if string.find req.headers['Content-Type'], "multipart/form-data", 1, true
			permissions=getquery permissions, 'csv'
		else
			permissions=getquery permissions, 'list'
		expires=getquery expires, 'int', true
		if expires and expires<os.time!
			error "Already expired"
	unless ok
		return res\status(400)\json {:ok, :err}
	
	db.begin 'write', (commit, rollback) ->
		local key
		ok, err=pcall () ->
			auth.validatepassword password
			auth.cleanup!
			key=auth.createkey name, permissions, expires
		unless ok
			rollback!
			return res\status(500)\json {:ok, :err}
		
		commit!
		res\json {:ok, res: key}
