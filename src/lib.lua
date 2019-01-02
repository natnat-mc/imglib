-- load everything
local util=require 'util'
local config=require 'config'
local sqlite=util.tryrequire 'lsqlite3complete' or require 'lsqlite3'
local fs=require 'lfs'

-- create the library
local lib={}

-- internal functions
local function prepare(sql)
	local a, b=lib.db:prepare(sql)
	if a then
		return a
	else
		print 'In SQL'
		print(sql)
		print(b, lib.db:errmsg())
		return nil
	end
end
local function exec(sql)
	local a, b, c=util.tryexec(lib.db, sql)
	if not a then
		print 'In SQL'
		print(sql)
		print(b, c)
		return nil
	end
	return true
end

-- prepared statement execution
local function getrow(stat, ...)
	if not stat then
		error "No statement given"
	end
	local row
	local a=stat:bind_values(...)
	if a~=0 then
		error("Error while binding values: "..a)
	end
	for r in stat:nrows() do
		row=r
	end
	stat:reset()
	return row
end
local function getrows(stat, ...)
	if not stat then
		error "No statement given"
	end
	local rows, i={}, 1
	local a=stat:bind_values(...)
	if a~=0 then
		error("Error while binding values: "..a)
	end
	for row in stat:nrows() do
		rows[i], i=row, i+1
	end
	stat:reset()
	return rows
end
local function run(stat, ...)
	if not stat then
		error "No statement given"
	end
	local a=stat:bind_values(...)
	if a~=0 then
		error("Error while binding values: "..a)
	end
	a=stat:step()
	stat:reset()
	if a~=sqlite.DONE then
		error("Error while executing statement: "..a)
	end
end
local function insert(stat, ...)
	run(stat, ...)
	return stat:last_insert_rowid()
end

-- function creation
local function create(fn, stat, args, nsfwstat)
	if not args then
		if not nsfwstat then
			-- simply exec the statement
			return (function()
				return fn(stat)
			end)
		else
			-- exec a different statement if nsfw mode is on
			return (function(nsfw)
				return fn(nsfw and nsfwstat or stat)
			end)
		end
	else
		-- reverse arg list
		local argmap={}
		local argc=#args
		for i, v in ipairs(args) do
			argmap[v]=i
		end
		
		if not nsfwstat then
			-- translate map into list and exec statement
			return (function(args)
				local list={}
				for arg, val in pairs(args) do
					list[argmap[arg]]=val
				end
				return fn(stat, table.unpack(list, 1, argc))
			end)
		else
			-- translate map into list and exec a different statement if nsfw mode is on
			return (function(args, nsfw)
				local list={}
				for arg, val in pairs(args) do
					list[argmap[arg]]=val
				end
				return fn(nsfw and nsfwstat or stat, table.unpack(list, 1, argc))
			end)
		end
	end
end

-- library load
function lib.load()
	-- open database and create statement list
	lib.db=sqlite.open(config.dbfile)
	lib.stat={}
	
	-- enforce foreign keys
	exec [[PRAGMA foreign_keys=ON;]]
	
	-- create temp tables used for finding tag combos
	exec [[
CREATE TEMP TABLE yestags(
	id INTEGER PRIMARY KEY
);]]
	exec [[
CREATE TEMP TABLE notags(
	id INTEGER PRIMARY KEY
);]]
	
	-- prepare all useful statements
	local preplist={
		-- format getters
		'getformats', -- all of them
		'getformatbyid', -- by id
		'getformatbyname', -- by name
		
		-- format adders
		'addformat', -- create a format
		
		-- tag getters
		'gettags', 'getalltags', -- all of them
		'gettagbyid', -- by id
		'gettagbyname', -- by name
		'gettagsforimage', -- for an image
		'gettagsforalbum', -- for an album
		
		-- tag adder
		'addtag', 'addnsfwtag', -- create a tag
		'addtagtoimage', -- add a tag to an image
		'addtagtoalbum', -- add a tag to an album
		
		-- album getters
		'getalbums', 'getallalbums', -- all of them
		'getalbumbyid', -- by id
		'getalbumbyname', -- by name
		'getalbumsfortag', 'getallalbumsfortag', -- for a tag
		'getalbumsfortags', 'getallalbumsfortags', -- for a tag combo
		'getalbumsforimage', 'getallalbumsforimage', -- for an image
		
		-- album adders
		'addalbum', 'addnsfwalbum', -- create an album
		'addimagetoalbum', -- add an image to an album
		
		-- image getters
		'getimages', 'getallimages', -- all of them
		'getimagebyid', -- by id
		'getimagebyname', -- by name
		'getimagesfortag', 'getallimagesfortag', -- for a tag
		'getimagesfortags', 'getallimagesfortags', -- for a tag combo
		'getimagesforalbum', 'getallimagesforalbum', -- for an album
		
		-- tag combo config
		'cleantags', -- remove all tags from combos
		'addyestag', -- add a 'yes' tag to the combo
		'removeyestag', -- remove a 'yes' tag from the combo
		'addnotag', -- add a 'no' tag to the combo
		'removenotag', -- remove a 'no' tag from the combo

		-- fingerprint getters
		'getfingerprints', -- all of them
		'getfingerprintsforimage', -- for a specific image
		'getmatchingfingerprints', -- match them against another
		
		-- fingerprint adders
		'addfingerprint', -- create a fingerprint
	}
	for i, name in ipairs(preplist) do
		local fd, err=io.open(config.sqldir..'/'..name..'.sql', 'r')
		if fd then
			local sql=fd:read '*a'
			local st=prepare(sql)
			if st then
				lib.stat[name]=st
			else
				print("Unable to load statement")
			end
			fd:close()
		else
			print("Unable to load SQL for "..name..": "..err)
		end
	end
	
	-- create basic lib functions
	do
		local stat=lib.stat
		-- format getters
		lib.getformats=create(getrows, stat.getformats)
		lib.getformatbyid=create(getrow, stat.getformatbyid, {'id'})
		lib.getformatbyname=create(getrow, stat.getformatbyname, {'name'})
		
		-- format adders
		lib.addformat=create(insert, stat.addformat, {'name'})
		
		-- tag getters
		lib.gettags=create(getrows, stat.gettags, nil, stat.getalltags)
		lib.gettagbyid=create(getrow, stat.gettagbyid, {'id'})
		lib.gettagbyname=create(getrow, stat.gettagbyname, {'name'})
		lib.gettagsforimage=create(getrows, stat.gettagsforimage, {'image'})
		lib.gettagsforalbum=create(getrows, stat.gettagsforalbum, {'album'})
		
		-- tag adders
		lib.addtag=create(insert, stat.addtag, {'name', 'color'}, stat.addnsfwtag)
		lib.addtagtoimage=create(insert, stat.addtagtoimage, {'tag', 'image'})
		lib.addtagtoalbum=create(insert, stat.addtagtoalbum, {'tag', 'album'})
		
		-- album getters
		lib.getalbums=create(getrows, stat.getalbums, nil, stat.getallalbums)
		lib.getalbumbyid=create(getrow, stat.getalbumbyid, {'id'})
		lib.getalbumbyname=create(getrow, stat.getalbumbyname, {'name'})
		lib.getalbumsfortag=create(getrows, stat.getalbumsfortag, {'tag'}, stat.getallalbumsfortag)
		lib.getalbumsforimage=create(getrows, stat.getalbumsforimage, {'tag'}, stat.getallalbumsforimage)
		
		-- album adders
		lib.addalbum=create(insert, stat.addalbum, {'name'}, stat.addnsfwalbum)
		lib.addimagetoalbum=create(insert, stat.addimagetoalbum, {'image', 'album', 'offset'})
		
		-- image getters
		lib.getimages=create(getrows, stat.getimages, nil, stat.getallimages)
		lib.getimagebyid=create(getrow, stat.getimagebyid, {'id'})
		lib.getimagebyname=create(getrow, stat.getimagebyname, {'name'})
		lib.getimagesfortag=create(getrows, stat.getimagesfortag, {'tag'}, stat.getallimagesfortag)
		lib.getimagesforalbum=create(getrows, stat.getimagesforalbum, {'album'}, stat.getallimagesforalbum)

		-- fingerprint getters
		lib.getfingerprints=create(getrows, statgetfingerptints)
		lib.getfingerprintsforimage=create(getrows, stat.getfingerprintsforimage, {'image'})
		lib.getmatchingfingerprints=create(getrows, stat.getmatchingfingerprints, {'original', 'maxdelta', 'maxn'})
		
		-- fingerprint adders
		lib.addfingerprint=create(insert, stat.addfingerprint, {'image', 'size', 'fingerprint'})
	end
end

-- library finalize
function lib.finalize()
	-- finalize and delete statements
	for k, s in pairs(lib.stat) do
		s:finalize()
	end
	lib.stat={}
	-- close and delete database
	lib.db:close()
	lib.db=nil
end

-- get filename for ID and extension
function lib.getfilename(id, ext)
	return config.imgdir..'/i'..id..'.'..ext
end

-- get albums for tag combo
function lib.getalbumsfortags(yes, no, nsfw)
	run(stat.cleantags)
	if yes then
		for i, tag in ipairs(yes) do
			run(stat.addyestag, tag)
		end
	end
	if no then
		for i, tag in ipairs(no) do
			run(stat.addnotag, tag)
		end
	end
	return getrows(nsfw and stat.getallalbumsfortags or stat.getalbumsfortags)
end
-- get images for tag combo
function lib.getimagesfortags(yes, no, nsfw)
	run(stat.cleantags)
	if yes then
		for i, tag in ipairs(yes) do
			run(stat.addyestag, tag)
		end
	end
	if no then
		for i, tag in ipairs(no) do
			run(stat.addnotag, tag)
		end
	end
	return getrows(nsfw and stat.getallimagesfortags or stat.getimagesfortags)
end

return lib
