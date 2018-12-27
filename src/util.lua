local util={}

-- require or nil
function util.tryrequire(mod)
	local a, b=pcall(require, mod)
	return a and b or nil
end

-- ask the user for confirmation
function util.confirm(prompt, default)
	prompt=prompt..'? ['
	if default then
		prompt=prompt..'Y/n'
	else
		prompt=prompt..'y/N'
	end
	prompt=prompt..'] '
	while true do
		io.write(prompt)
		local ans=io.read '*l'
		if ans then
			ans=ans:lower()
		end
		if ans=='y' then
			return true
		elseif ans=='n' then
			return false
		elseif ans=='' then
			return default
		end
	end
end

-- try executing a statement
function util.tryexec(db, stat)
	local a=db:exec(stat)
	if a==0 then
		return true
	else
		return nil, a, db:errmsg()
	end
end
-- print a select result
function util.tabselect(db, stat, names)
	print(table.concat(names, '\t'))
	for row in db:rows(stat) do
		print(table.concat(row, '\t'))
	end
	print()
end
-- dump a table select result
function util.dumpresult(tab)
	if #tab==0 and next(tab) then
		return util.dumpresult {tab}
	elseif #tab==0 then
		print "(empty table)"
	else
		local names={}
		for k in pairs(tab[1]) do
			table.insert(names, k)
		end
		print(table.concat(names, '\t'))
		for i, row in ipairs(tab) do
			local vals={}
			for k, name in ipairs(names) do
				table.insert(vals, row[name])
			end
			print(table.concat(vals, '\t'))
		end
	end
	print()
end

return util
