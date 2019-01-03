local M={}

function M.escape(part)
	-- convert the command part into a string
	part=type(part)=='string' and part or tostring(part)
	
	-- simple command parts don't need escaping
	if part:match [[^[a-zA-Z0-9._-]+$]] then
		return part
	end
	
	-- escape quotes and backslashes, since we will double-quote the part
	local esc=part:gsub('\\', '\\\\'):gsub('\"', '\\\"')
	
	-- return the escaped part
	return '"'..esc..'"'
end

function M.exec(command, args, mode)
	local s=command
	
	-- iterate all arguments
	for i, arg in ipairs(args) do
		
		if type(arg)=='number' then
			-- numbers don't need escaping
			s=s..' '..arg
		elseif type(arg)=='string' then
			-- string are escaped
			s=s..' '..M.escape(arg)
		elseif type(arg)=='table' then
			if arg[1] then
				-- arg pair tables have the argument unescaped, and the value escaped
				s=s..' -'..arg[1]..' '..M.escape(arg[2])
			elseif next(arg) then
				-- kv tables are iterated as arg pairs
				for k, v in pairs(arg) do
					s=s..' -'..k..' '..M.escape(v)
				end
			else
				error("Empty table in arguments")
			end
		else
			error("Unknown type for arguments")
		end
	end
	
	-- run the command
	if mode=='r' then
		return io.popen(s, 'r')
	elseif mode=='w' then
		return io.popen(s, 'w')
	elseif mode=='cmd' then
		return s
	else
		return os.execute(s)
	end
end

function M.fingerprint(file, size)
	local command='convert'
	local args={
		file,
		{'resize', size..'x'..size..'!'},
		{'depth', 8},
		'rgb:-'
	}
	local mode='r'
	
	local fd=M.exec(command, args, mode)
	if not fd then
		error("Couldn't open imagemagick")
	end
	local fingerprint=fd:read '*a'
	if not fingerprint then
		fd:close()
		error("Couldn't read fingerprint")
	end
	if not fd:close() then
		error("Imagemagick exited with non-zero code")
	end
	return fingerprint
end

function M.resize(file, size, outfile)
	-- find an output file if not provided
	if not outfile then
		outfile=os.tmpname()
	end
	
	-- resize the file
	local command='convert'
	local args={
		file,
		{'resize', size},
		outfile
	}
	local mode='exec'
	if not M.exec(command, args, mode) then
		error("Imagemagick exited with non-zero code")
	end
	
	return outfile
end

return M
