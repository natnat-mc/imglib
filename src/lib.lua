-- load everything
local util=require 'util'
local config=require 'config'
local sqlite=util.tryrequire 'lsqlite3complete' or require 'lsqlite3'
local fs=require 'lfs'

-- create the library
local lib={}

-- library load
function lib.load()
	-- open database and create statement list
	lib.db=sqlite.open(config.dbfile)
	lib.stat={}
	
	-- load SQL wrapper
	lib.wrapper=require 'sqlwrapper'.install(lib.db)
	
	-- setup DB
	lib.wrapper.exec [[
PRAGMA foreign_keys=ON;

CREATE TEMP TABLE yestags(
	id INTEGER PRIMARY KEY
);

CREATE TEMP TABLE notags(
	id INTEGER PRIMARY KEY
);
]]
	
	-- create SQL functions
	require 'sqlfuncs'.install(lib.db)
	
	-- prepare statements
	lib.stat=require 'sqlstatements'.install(lib.db)
	
	-- create basic lib functions
	do
		-- bind single letters
		local L=lib
		local S=lib.stat
		local C=lib.wrapper.create
		local O, R, I=lib.wrapper.getrow, lib.wrapper.getrows, lib.wrapper.insert
		
		
		-- format getters
		L.getformats=C {
			stat=S.getformats,
			executor=R
		}
		L.getformatbyid=C {
			stat=S.getformatbyid,
			executor=O,
			params={'id'}
		}
		L.getformatbyname=C {
			stat=S.getformatbyname,
			executor=O,
			params={'name'}
		}
		
		-- format adders
		L.addformat=C {
			stat=S.addformat,
			executor=I,
			params={'name'}
		}
		
		-- tag getters
		L.gettags=C {
			stat=S.gettags,
			nsfwstat=S.getalltags,
			executor=R
		}
		L.gettagbyid=C {
			stat=S.gettagbyid,
			executor=O,
			params={'id'}
		}
		L.gettagbyname=C {
			stat=S.gettagbyname,
			executor=O,
			params={'name'}
		}
		L.gettagsforimage=C {
			stat=S.gettagsforimage,
			executor=R,
			params={'image'}
		}
		L.gettagsforalbum=C {
			stat=S.gettagsforalbum,
			executor=R,
			params={'album'}
		}
		
		-- tag adders
		L.addtag=C {
			stat=S.addtag,
			nsfwstat=S.addnsfwtag,
			executor=I,
			params={'name', 'color'},
			defval={color='555555'}
		}
		L.addtagtoimage=C {
			stat=S.addtagtoimage,
			executor=I,
			params={'tag', 'image'}
		}
		L.addtagtoalbum=C {
			stat=S.addtagtoalbum,
			executor=I,
			params={'tag', 'album'}
		}
		
		-- album getters
		L.getalbums=C {
			stat=S.getalbums,
			nsfwstat=S.getallalbums,
			executor=R
		}
		L.getalbumbyid=C {
			stat=S.getalbumbyid,
			executor=O,
			params={'id'}
		}
		L.getalbumbyname=C {
			stat=S.getalbumbyname,
			executor=O,
			params={'id'}
		}
		L.getalbumsfortag=C {
			stat=S.getalbumsfortag,
			nsfwstat=S.getallalbumsfortag,
			executor=R,
			params={'tag'}
		}
		L.getalbumsforimage=C {
			stat=S.getalbumsforimage,
			nsfwstat=S.getallalbumsforimage,
			executor=R,
			params={'image'}
		}
		
		-- album adders
		L.addalbum=C {
			stat=S.addalbum,
			nsfwstat=S.addnsfwalbum,
			executor=I,
			params={'name'}
		}
		L.addimagetoalbum=C {
			stat=S.addimagetoalbum,
			executor=I,
			params={'image', 'album', 'offset'},
			defval={offset=0}
		}
		
		-- image getters
		L.getimages=C {
			stat=S.getimages,
			nsfwstat=S.getallimages,
			executor=R,
		}
		L.getimagebyid=C {
			stat=S.getimagebyid,
			executor=O,
			params={'id'}
		}
		L.getimagebyname=C {
			stat=S.getimagebyname,
			executor=O,
			params={'name'}
		}
		L.getimagesfortag=C {
			stat=S.getimagesfortag,
			nsfwstat=S.getallimagesfortag,
			executor=R,
			params={'tag'}
		}
		L.getimagesforalbum=C {
			stat=S.getimagesforalbum,
			nsfwstat=S.getallimagesforalbum,
			executor=R,
			params={'album'}
		}

		-- fingerprint getters
		L.getfingerprints=C {
			stat=S.getfingerprints,
			executor=R
		}
		L.getfingerprintsforimage=C {
			stat=S.getfingerprintsforimage,
			executor=R,
			params={'image'}
		}
		L.getmatchingfingerprints=C {
			stat=S.getmatchingfingerprints,
			executor=R,
			params={'original', 'maxdelta', 'maxn'},
			defval={maxdelta=.5, maxn=5}
		}
		
		-- fingerprint adders
		L.addfingerprint=C {
			stat=S.addfingerprint,
			executor=I,
			params={'image', 'size', 'fingerprint'}
		}
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
