local a, b=pcall(require, 'lsqlite3')
if a then
	return b
else
	return require 'lsqlite3complete'
end
