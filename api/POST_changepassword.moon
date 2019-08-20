auth=require './auth'
authenticate=require './authenticate'
getquery=require './getquery'

(req, res) ->
	return unless authenticate req, res, {'api'}
	
	import oldpassword, newpassword from req.body
	ok, err=pcall () ->
		unless pcall getquery, oldpassword, 'string'
			error "Old password must be a string"
		unless pcall getquery, newpassword, 'string'
			error "New password must be a string"
		if oldpassword==newpassword
			error "New password can't be old password"
	unless ok
		return res\status(400)\json {:ok, :err}
	
	ok, err=pcall auth.changepassword, oldpassword, newpassword
	if ok
		return res\json {:ok}
	else
		return res\status(400)\json {:ok, :err}
