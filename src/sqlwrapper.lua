local sqlite=require 'sqlite'

-- create module
local M={}

function M.install(db, L)
	-- create lib table if lib doesn't exist
	if not L then
		L={}
	end
	
	-- execute SQL statements, throw on error
	function L.exec(sql)
		if db:exec(sql)~=0 then
			error("Error while executing SQL: "..db:errmsg())
		end
	end
	
	-- bind parameters on statement, throw on error
	function L.bind(stat, params)
		if stat:bind_names(params)~=0 then
			error("Error while binding parameters: "..db:errmsg())
		end
	end
	
	-- get one row of a result
	function L.getrow(stat, params)
		-- bind the statement
		L.bind(stat, params)
		
		-- execute the statement
		if stat:step()~=sqlite.ROW then
			error("Error while executing statement: "..db:errmsg())
		end
		
		-- read values
		local names=stat:get_names()
		local values=stat:get_values()
		local row={}
		for i=1, #names do
			row[names[i]]=values[i]
		end
		
		-- reset the statement
		stat:reset()
		
		-- return the row
		return row
	end
	
	-- get all the rows of a result
	function L.getrows(stat, params)
		-- bind the statement
		L.bind(stat, params)
		
		-- execute the statement and read values
		local rows, i={}, 1
		for row in stat:nrows() do
			rows[i], i=row, i+1
		end
		
		-- reset the statement
		stat:reset()
		
		return rows
	end
	
	-- execute a statement that doesn't return anything
	function L.execute(stat, params)
		-- bind the statement
		L.bind(stat, params)
		
		-- execute the statement
		if stat:step()~=sqlite.DONE then
			error("Error while executing statement: "..db:errmsg())
		end
		
		-- reset the statement
		stat:reset()
	end
	
	-- execute a statement and return last inserted ROWID
	function L.insert(stat, params)
		-- execute the statement
		L.execute(stat, params)
		
		-- return last ROWID
		return stat:last_insert_rowid()
	end
	
	-- create a function that executes a statement
	function L.create(config)
		-- extract data from config
		local stat=config.stat or nil
		local nsfwstat=config.nsfwstat or nil
		local params=config.params or nil
		local defval=config.defval or {}
		local executor=config.executor or nil
		
		-- sanity check
		if not stat then
			error("Attempt to create statement executor without statement")
		end
		if not executor then
			error("Attempt to create statement executor without executor")
		end
		
		-- argument checking function
		local function argcheck(args)
			for i, v in ipairs(params) do
				if args[v]==nil then
					args[v]=defval[v]
					if args[v]==nil then
						error("Missing parameter "..v.." without default value")
					end
				end
			end
			return args
		end
		
		-- return a matching function
		if params and nsfwstat then
			-- parameters, nsfw form
			return (function(args) return executor(args.nsfw and nsfwstat or stat, argcheck(args)) end)
		elseif params then
			-- parameters, no nsfw form
			return (function(args) return executor(stat, argcheck(args)) end)
		elseif nsfwstat then
			-- no parameters, nsfw form
			return (function(nsfw) return executor(nsfw and nsfwstat or stat, {}) end)
		else
			-- no parameters, no nsfw form
			return (function() return executor(stat, {}) end)
		end
	end
	
	-- return the lib
	return L
end

return M
