-- load everything
local util=require 'util'
local config=require 'config'
local sqlite=util.tryrequire 'lsqlite3complete' or require 'lsqlite3'
local fs=require 'lfs'

-- create the library
local lib={}

-- execute sql code
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
	
	-- create SQL functions
	require 'sqlfuncs'.install(lib.db)
	
	-- prepare statements
	lib.stat=require 'sqlstatements'.install(lib.db)
	
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
		lib.getfingerprints=create(getrows, stat.getfingerprints)
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
