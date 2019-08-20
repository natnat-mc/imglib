db=require '../db'
config=require '../app/config'
getrandom=require '../libs/getrandom'

validatekey=db.Statement.get 'key/validate'
cleanupkeys=db.Statement.get 'key/cleanup'
deletenamedkey=db.Statement.get 'key/deleteforname'
listkeys=db.Statement.get 'key/list'
deleteidkey=db.Statement.get 'key/deleteforid'
existskey=db.Statement.get 'key/exists'

permval={
	read: 1,
	upload: 2,
	write: 6,
	api: 7
}

permstr={
	[1]: 'read',
	[2]: 'upload',
	[6]: 'write',
	[7]: 'api'
}

getperm=(permlist) ->
	perm=0
	for permstr in *permlist
		permint=permval[permstr]
		error "Invalid permission #{permstr}" unless permint
		perm=bit.bor perm, permint
	return perm

getpermstring=(permint) ->
	return permstr[permint] or error "Invalid permission int: #{permint}"

getpermlist=(permint) ->
	list={}
	for k, v in pairs permstr
		if k==bit.band k, permint
			table.insert list, v
	return list

getkey=(req) ->
	-- can (and should) be executed OUTISDE of an explicit transaction
	keystr, keyloc=req.query.key, 'query'
	keystr, keyloc=req.headers['API-Key'], 'header' unless keystr
	keystr, keyloc=req.cookie.key, 'cookie' unless keystr
	
	unless keystr
		keyloc='none'
		key={permissions: 0}
		return key, keyloc
	
	--FIXME we're probably vulnerable to timing attacks, but with a potentially large ammount of keys, it might be fine
	ok, key=pcall validatekey\getrow, {key: keystr}
	unless ok
		error "Invalid key"
	
	return key, keyloc

validatepassword=(test) ->
	password=config.password
	-- this should be (more or less) safe against timing attacks, unless luajit decides to optimize it
	matching=#test==#password
	for i=1, math.max #test, #password
		if (test\sub i, i)!=(password\sub i, i)
			matching=false
		else
			matching=matching
	error "Invalid password" unless matching

changepassword=(oldpass, newpass) ->
	validatepassword oldpass
	config.password=newpass
	(getmetatable config).update!

createkey=(name, permissions, expires) ->
	-- MUST BE EXECUTED INSIDE A WRITE TRANSACTION
	permint=getperm permissions
	permissions=getpermlist permint
	key=getrandom config.randomsize
	
	deletenamedkey\execute {:name}
	id=db.TemplatedStatement.insert 'key/create', {expires: expires and true}, {:name, permissions: permint, :expires, :key}
	
	return {:id, :name, :permissions, :expires, :key}

getkeys=() ->
	-- MUST BE EXECUTED INSIDE A TRANSACTION
	keys={}
	for row in listkeys\iterate!
		table.insert keys, {
			id: row.id, name: row.name, expires: row.expires
			permissions: getpermlist row.permissions
		}
	return keys

keyidexists=(id) ->
	-- SHOULD be executed inside a transaction
	return existskey\has {:id}

deletekey=(id) ->
	-- MUST BE EXECUTED INSIDE A WRITE TRANSACTION
	deleteidkey\execute {:id}

cleanup=() ->
	-- MUST BE EXECUTED INSIDE A WRITE TRANSACTION
	cleanupkeys\execute {now: os.time!}

return {
	:getperm, :getpermstring, :getpermlist
	:validatepassword, :changepassword
	:getkey, :createkey, :getkeys, :deletekey, :keyidexists
	:cleanup
}
