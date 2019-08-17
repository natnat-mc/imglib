local ServerResponse=require('http').ServerResponse
local Builder=require('jsonstream').Builder

local function copy(a, b)
	local o={}
	for k, v in pairs(b or {}) do
		o[k]=v
	end
	for k, v in pairs(a or {}) do
		o[k]=v
	end
	return o
end

function ServerResponse:sendHead(code, header, data)
	if self._headerSent then
		p("------------------------------")
		p("Error", "Header Has Been Sent.")
		p("------------------------------")
		return true
	end
	self._headerSent = true
	code = code or self.statusCode or 200
	self:status(code)
	header = copy(copy(header, self.headers), {
		["Connection"] = "keep-alive",
		["Content-Type"] = "text/html; charset=utf-8",
		["X-Served-By"] = "MoonCake",
		["Content-Length"] = data and #data
	})
	self:writeHead(self.statusCode, header)
end

function ServerResponse:stream(iterator, transform, endfn)
	local ok, val=pcall(iterator)
	if ok then
		self:sendHead(200, {['Content-Type']= 'application/json', ['Connection']= 'close'})
		local writecoro
		local builder=Builder:new(function(e)
			if self:write(e)==false then
				self:once('drain', function() coroutine.resume(writecoro) end)
				coroutine.yield()
			end
		end)
		writecoro=coroutine.create(function()
			builder:startObject():put(true, 'ok'):startArray('res')
			if val then
				builder:put(transform(val))
				for val in iterator do
					builder:put(transform(val))
				end
			end
			builder:endArray()
			builder:endObject()
			self:finish()
			endfn()
		end)
		coroutine.resume(writecoro)
	else
		self:status(500):send{['ok']=false, ['err']=val}
	end
end

function ServerResponse:stream2(statusfn, transform)
	local buffer, ready, write, drain, builder
	local first=true
	
	self:sendHead(200, {['Content-Type']= 'application/json', ['Connection']= 'close'})
	self:once('close', function() statusfn('abort') end)
	self:once('error', function() statusfn('abort') end)
	
	buffer={}
	ready=true
	write=function(e)
		if not ready then
			table.insert(buffer, e)
		elseif e==false then
			self:finish()
			statusfn('transmitted')
		elseif self:write(e)==false then
			ready=false
			statusfn('pause')
			self:once('drain', drain)
		end
	end
	drain=function(e)
		ready=true
		statusfn('resume')
		while ready and #buffer~=0 do
			local e=table.remove(buffer, 1)
			if e==false then
				self:finish()
				statusfn('transmitted')
			elseif self:write(e)==false then
				ready=false
				statusfn('pause')
				self:once('drain', drain)
			end
		end
	end
	builder=Builder:new(write)
	
	return function(command, data)
		if first then
			if command=='row' then
				builder:startObject():put(true, 'ok'):startArray('res')
				builder:put(transform(data))
			elseif command=='finish' then
				builder:startObject():put(true, 'ok'):startArray('res'):endArray():endObject()
				statusfn('finish')
				write(false)
			elseif command=='error' then
				builder:startObject():put(false, 'ok'):put(data, 'err'):endObject()
				statusfn('error')
				write(false)
				print("Error: "..data)
			end
			first=false
		else
			if command=='row' then
				builder:put(transform(data))
			elseif command=='finish' then
				builder:endArray():endObject()
				statusfn('finish')
				write(false)
			elseif command=='error' then
				builder:endArray():put(data, 'err'):endObject()
				statusfn('error')
				write(false)
				print("Error: "..data)
			end
		end
	end
end

function ServerResponse:streamStatement(stmt, vals, transform, endfn)
	local threadctl, streamctl
	
	local function streamcmd(command)
		if command=='finish' or command=='error' or command=='abort' or command=='stop' then
			pcall(endfn)
		end
		if command=='pause' or command=='resume' or command=='abort' or command=='stop' then
			threadctl(command)
		end
	end
	
	streamctl=self:stream2(streamcmd, transform)
	threadctl=stmt:iterate2(vals, streamctl)
end
