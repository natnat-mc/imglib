local fs=require 'fs'

-- it used to lead fd's, so now it doesn't
fs.readFileSync=function(path)
	local fd, err, data
	fd, err=io.open(path, 'r')
	if not fd then
		return nil, err
	end
	data, err=fd:read '*a'
	fd:close()
	return data, err
end
