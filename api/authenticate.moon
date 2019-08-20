import getkey, getperm, getpermstring from require './auth'

(req, res, permissions) -> 
	ok, key, keyloc=pcall getkey, req
	unless ok
		res\status(403)\json {ok: false, err: "Invalid API Key", autherror: true}
		print key
		return false
	perm=getperm permissions
	if perm!=0
		if not key
			res\status(401)\json {ok: false, err: "API Key not supplied", autherror: true}
			return false
		if perm!=bit.band perm, key.permissions
			res\status(403)\json {ok: false, err: "Insufficient permissions: missing #{getpermstring bit.band perm, bit.bnot key.permissions}", autherror: true, :keyloc}
			return false
	if key and key.expires and key.expires<os.time!
		res\status(403)\json {ok: false, err: "API Key expired", autherror: true, :keyloc}
		return false
	return true
