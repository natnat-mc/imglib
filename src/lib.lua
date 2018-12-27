-- load everything
local util=require 'util'
local config=require 'config'
local sqlite=util.tryrequire 'lsqlite3complete' or require 'lsqlite3'
local fs=require 'lfs'

-- internal variables
local db
local stat={}

-- internal functions
local function prepare(sql)
	local a, b=db:prepare(sql)
	if a then
		return a
	else
		print 'In SQL'
		print(sql)
		print(b, db:errmsg())
		return nil
	end
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

-- create the library
local lib={}

-- library load
function lib.load()
	-- open database
	db=sqlite.open(config.dbfile)

	-- create statements
	stat.gettags=prepare [[
SELECT id, name, color, nsfw
	FROM tags
	WHERE nsfw=0;]]
	stat.getalltags=prepare [[
SELECT id, name, color, nsfw
	FROM tags;]]
	stat.gettagbyid=prepare [[
SELECT id, name, color, nsfw
	FROM tags
	WHERE id=:id;]]
	stat.gettagbyname=prepare [[
SELECT id, name, color, nsfw
	FROM tags
	WHERE name=:name;]]
	stat.gettagsforimage=prepare [[
SELECT id, name, color, nsfw
	FROM tags t, imagetag it
	WHERE t.id=it.tag AND it.image=:id;]]
	
	stat.getformats=prepare [[
SELECT id, name
	FROM formats;]]
	stat.getformatbyid=prepare [[
SELECT id, name
	FROM formats
	WHERE id=:id;]]
	stat.getformatbyname=prepare [[
SELECT id, name
	FROM formats
	WHERE name=:name;]]

	stat.getimages=prepare [[
SELECT i.id, i.name, nsfw, f.name AS format, height, width, adddate
	FROM images i, formats f
	WHERE i.format=f.id AND nsfw=0;]]
	stat.getallimages=prepare [[
SELECT i.id, i.name, nsfw, f.name AS format, height, width, adddate
	FROM images i, formats f
	WHERE i.format=f.id;]]
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
	return getrows(nsfw and stat.getalltags or stat.gettags)
end
-- get tag by id
function lib.gettagbyid(id)
	return getrow(stat.gettagbyid, id)
end
-- get tag by name
function lib.gettagbyname(name)
	return getrow(stat.gettagbyname, name)
end
-- get tags for image
function lib.gettagsforimage(id)
	return getrows(stat.gettagsforimage, id)
end

-- get formats
function lib.getformats(id)
	return getrows(stat.getformats)
end
-- get format by id
function lib.getformatbyid(id)
	return getrow(stat.getformatbyid, id)
end
-- get format by name
function lib.getformatbyname(name)
	return getrow(stat.getformatbyname, name)
end

-- get images
function lib.getimages(nsfw)
	return getrows(nsfw and stat.getallimages or stat.getimages)
end

return lib
