sqlite3=require 'lsqlite3'
fs=require 'fs'
thread=require 'thread'
native=require '../native'
JSON=require 'JSON'
config=require '../app/config'
import ObjectDecodeStream from require 'jsonstream'
import insert, remove from table

fncode=fs.readFileSync "./db/functions.lua"

class Statement
	statements={}
	@get: (name) ->
		-- create a statement group if they don't exist
		statements[name]=@ name unless statements[name]
		return statements[name]
	
	new: (name) =>
		@readypool={}
		@code=fs.readFileSync "sql/#{name}.sql", 'utf8'
		error "Couldn't read statement" unless @code
		@_create!
	
	-- prepare a statement
	_create: () =>
		stat=@@db\prepare @code
		error @@db\errmsg! if not stat
		insert @readypool, stat
	
	-- bind a statement, and create it if needed
	_prep: (vals) =>
		@_create! unless #@readypool!=0
		stat=remove @readypool
		if vals and sqlite3.OK!=stat\bind_names vals
			insert @readypool, stat
			error @@db\errmsg!
		return stat
	
	-- Iterate in the current thread
	-- Note that this is actually synchronous
	@iterate: (name, vals) -> (@.get name)\iterate vals
	iterate: (vals) =>
		stat=@_prep vals
		
		return coroutine.wrap () ->
			coroutine.yield line for line in stat\nrows!
			stat\reset!
			insert @readypool, stat
			return nil
	
	-- Iterate in another thread with controls
	-- This is necessary, since lsqlite3 is blocking
	@iterate2: (name, vals, fn) -> (@.get name)\iterate2 vals, fn
	iterate2: (vals, fn) =>
		-- create two pipes for inter-thread communication
		controlread, controlwrite=native.pipe!
		dataread, datawrite=native.pipe!
		
		-- thread status
		status='running'
		
		-- worker thread code
		threadfn=(dbpath, stmtcode, valsjson, controlfd, datafd, fncode) ->
			-- try and report errors
			try=(fn, ...) ->
				ok, err=pcall fn, ...
				print "Error in try: #{err}" unless ok
				ok
			
			-- load required libs
			native=require 'native'
			import stringify, parse from require 'JSON'
			sqlite3=require 'lsqlite3'
			
			-- store the statement here, so that we can finalize it
			local stmt
			
			-- enter protected mode
			ok, err=pcall () ->
				-- load the database, statement and values
				db=sqlite3.open dbpath, sqlite3.OPEN_READWRITE+sqlite3.OPEN_CREATE+sqlite3.OPEN_FULLMUTEX
				(load fncode, "./db/functions.lua")! db
				stmt=db\prepare stmtcode
				vals=parse valsjson
				
				-- prepare and run the statement
				if vals and (next vals) and sqlite3.OK!=stmt\bind_names vals
					error db\errmsg!
				nextrow=do
					a, b=stmt\nrows!
					() -> a b
				
				-- enter main loop
				while true
					if native.canread controlfd
						cmd=native.read controlfd, 1
						if cmd=='P'
							paused=true
							while paused
								cmd=native.read controlfd, 1
								paused=false if cmd=='R'
								error "Aborted" if cmd=='S'
						elseif cmd=='S'
							error "Aborted"
					row=nextrow!
					break unless row
					native.write datafd, stringify {kind: 'row', data: row}
			
			-- clean up
			try () -> stmt\finalize!
			
			-- report status and die
			try () ->
				if ok
					native.write datafd, stringify {kind: 'finish'}
				else
					native.write datafd, stringify {kind: 'error', data: err}
			try native.close, datafd
			try native.close, controlfd
		
		-- control function
		control=(command) ->
			switch command
				when 'status'
					return status
				when 'stop', 'abort'
					return false if status!='running'
					return pcall native.write, controlwrite, 'S'
				when 'pause'
					return false if status!='running'
					return pcall native.write, controlwrite, 'P'
				when 'resume'
					return false if status!='running'
					return pcall native.write, controlwrite, 'R'
				else
					error "Unrecognized command: #{command}"
		
		-- event listener
		datastream=fs.createReadStream '', {fd: dataread}
		events=datastream\pipe ObjectDecodeStream\new!
		events\on 'data', (msg) ->
			switch msg.kind
				when 'finish'
					status='finished'
					native.close controlwrite
					datastream\close!
					fn 'finish', nil
				when 'error'
					status='errored'
					native.close controlwrite
					datastream\close!
					fn 'error', msg.data
				when 'row'
					fn 'row', msg.data
		
		-- start the thread and return the controller
		native.startthread threadfn, config.data.database, @code, (JSON.stringify vals), controlread, datawrite, fncode
		return control
	
	-- get a single row of data
	@getrow: (name, vals) -> (@.get name)\getrow vals
	getrow: (vals) =>
		stat=@_prep vals
		
		error @@db\errmsg! unless sqlite3.ROW==stat\step!
		names=stat\get_names!
		values=stat\get_values!
		row={}
		row[name]=values[i] for i, name in ipairs names
		stat\reset!
		insert @readypool, stat
		return row
	
	-- get a single value
	@getsingle: (name, vals) -> (@.get name)\getsingle vals
	getsingle: (vals) =>
		stat=@_prep vals
		
		error @@db\errmsg! unless sqlite3.ROW==stat\step!
		val=stat\get_value 0
		stat\reset!
		insert @readypool, stat
		return val
	
	-- gets a single value and checks if it's 1, useful for SELECT COUNT(1)
	@has: (name, vals) -> (@.get name)\has vals
	has: (vals) =>
		ok, val=pcall () -> @getsingle vals
		return ok and val==1
	
	-- executes a statement without any results
	@execute: (name, vals) -> (@.get name)\execute vals
	execute: (vals) =>
		stat=@_prep vals
		
		unless sqlite3.DONE==stat\step!
			stat\reset!
			insert @readypool, stat
			error @@db\errmsg!
		insert @readypool, stat
		stat\reset!
		return nil
	
	-- executes an UPDATE statement and returns the ROWID
	@update: (name, vals) -> (@.get name)\update vals
	update: (vals) => @insert vals
	
	-- executes an INSERT statement and returns the ROWID
	@insert: (name, vals) -> (@.get name)\insert vals
	insert: (vals) =>
		stat=@_prep vals
		
		unless sqlite3.DONE==stat\step!
			stat\reset!
			insert @readypool, stat
			error @@db\errmsg!
		insert @readypool, stat
		rowid=stat\last_insert_rowid!
		stat\reset!
		return rowid
	
	-- finalize all instances of this statement
	-- this is basically useless, but hey, why not?
	finalize: () =>
		stat\finalize! for stat in *@readypool
		@readypool={}
