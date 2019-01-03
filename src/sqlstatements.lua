local config=require 'config'

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

local M={}

-- install all statements
function M.install(db)
	local S={}
	for i, name in ipairs(preplist) do
		local fd=io.open(config.sqldir..'/'..name..'.sql', 'r')
		if not fd then
			error("Couldn't load statement "..name)
		end
		local code=fd:read '*a'
		if not code then
			error("Couldn't read statement "..name)
		end
		fd:close()
		local stat=db:prepare(code)
		if not stat then
			error("Couldn't prepare statement "..name..":\n"..db:errmsg())
		end
		S[name]=stat
	end
	return S
end

-- install statements for lazy loading
function M.lazyinstall(db)
	local S={}
	local _={}
	
	-- reverse preplist for faster lookup
	local rev={}
	for i, v in ipairs(preplist) do
		rev[v]=true
	end
	
	-- dynamically load statements as they are used
	function _:__index(name)
		if not rev[name] then
			error("Attempt to use nonexistent statement "..name)
		end
		
		-- open statement file
		local fd=io.open(config.sqldir..'/'..name..'.sql', 'r')
		if not fd then
			error("Couldn't load statement "..name)
		end
		
		-- read statement code
		local code=fd:read '*a'
		if not code then
			error("Couldn't read statement "..name)
		end
		fd:close()
		
		-- prepare statement
		local stat=db:prepare(code)
		if not stat then
			error("Couldn't prepare statement "..name..":\n"..db:errmsg())
		end
		
		-- add statement to the table and return it
		rawset(self, name, stat)
		return stat
	end
	
	return setmetatable(S, _)
end

return M

