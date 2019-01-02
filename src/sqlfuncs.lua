local M={}
local func={}

-- calculates the difference between two blobs
function M.delta(ctx, a, b)
	local l=#a
	if l~=#b then
		return ctx:result_error "Blobs must have the same length"
	end
	local diff=0
	for i=1, l do
		local ba, bb=a:byte(i, i), b:byte(i, i)
		local ld=ba-bb
		if ld<0 then
			ld=-ld
		end
		diff=diff+ld
	end
	return ctx:result_number(diff/l/255)
end
func.delta=2

-- calculate the difference between two images
local invsqrt3=1/math.sqrt(3)
local function colordelta(r1, g1, b1, r2, g2, b2)
	local r=(r1-r2)/255
	local g=(g1-g2)/255
	local b=(b1-b2)/255
	local d=math.sqrt(r*r+g*g+b*b)*invsqrt3
	return d
end
function M.imagedelta(ctx, a, b)
	local len=#a/3
	if len~=#b/3 then
		return ctx:result_error "Blobs must have the same length"
	end
	if len%1~=0 then
		return ctx:result_error "Blobs must have a length multiple of three"
	end
	local delta=0
	for i=0, len-1 do
		local r1, g1, b1=a:byte(len*3+1, len*3+3)
		local r2, g2, b2=b:byte(len*3+1, len*3+3)
		delta=delta+colordelta(r1, g1, b1, r2, g2, b2)
	end
	return ctx:result_number(delta/len)
end
func.imagedelta=2

-- install all custom functions
function M.install(db)
	for k, n in pairs(func) do
		if n<0 then
			db:create_aggregate(k, -n, M[k]())
		else
			db:create_function(k, n, M[k])
		end
	end
end

return M
