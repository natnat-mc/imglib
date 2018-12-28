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
end

-- library finalize
function lib.finalize()
	-- finalize and delete statements
	local a={}
	for k, s in pairs(stat) do
		table.insert(a, k)
		s:finalize()
	end
	for i, v in ipairs(a) do
		stat[v]=nil
	end
	-- close and delete database
	db:close()
	db=nil
end

-- get filename for ID and extension
function lib.getfilename(id, ext)
	return config.imgdir..'/i'..id..'.'..ext
end

-- get all the tags
function lib.gettags(nsfw)
	return getrows(nsfw and lib.stat.getalltags or lib.stat.gettags)
end
-- get tag by id
function lib.gettagbyid(id)
	return getrow(lib.stat.gettagbyid, id)
end
-- get tag by name
function lib.gettagbyname(name)
	return getrow(lib.stat.gettagbyname, name)
end
-- get tags for image
function lib.gettagsforimage(id)
	return getrows(lib.stat.gettagsforimage, id)
end

-- get formats
function lib.getformats(id)
	return getrows(lib.stat.getformats)
end
-- get format by id
function lib.getformatbyid(id)
	return getrow(lib.stat.getformatbyid, id)
end
-- get format by name
function lib.getformatbyname(name)
	return getrow(lib.stat.getformatbyname, name)
end

-- get images
function lib.getimages(nsfw)
	return getrows(nsfw and lib.stat.getallimages or lib.stat.getimages)
end
-- get images for tag
function lib.getimagesfortag(tag, nsfw)
	if type(tag)=='string' then
		tag=lib.gettagbyname(tag).id
	end
	return getrows(nsfw and lib.stat.getallimagesfortag or lib.stat.getimagesfortag, tag)
end

return lib
