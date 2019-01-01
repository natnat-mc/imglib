local M={}
local func={}

-- calculates the difference between two blobs
function M.delta(ctx, a, b)
	local l=#a
	if l~=#b then
		ctx:result_error "Blobs must have the same length"
	end
	local diff=0
	for i=1, l do
		local ba, bb=a:byte(i, i), b:byte(i, i)]
		local ld=ba-bb
		if ld<0 then
			ld=-ld
		end
		diff=diff+ld
	end
	ctx:result_number(diff/l/255)
end
func.delta=2

-- install all custom functions
function M.install(db)
	for k, n in pairs(funcs) do
		if n<0 then
			db:create_aggregate(k, -n, M[k]())
		else
			db:create_function(k, n, M[k])
		end
	end
end

return M
