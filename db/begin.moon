(exec) ->
	writing, reading, writequeue, readqueue=false, 0, {}, {}
	enqueue=(queue, val) -> table.insert queue, val
	dequeue=(queue) -> table.remove queue, 1
	
	-- start the next db operation(s)
	nextinline=() ->
		if #writequeue!=0
			begin 'write', dequeue writequeue
		else
			rq, readqueue=readqueue, {}
			for fn in *rq
				begin 'read', fn
	
	-- we're not reading anymore
	stopreading=() ->
		reading=reading-1
		nextinline! if reading==0
	
	-- we're not writing anymore
	stopwriting=() ->
		writing=false
		nextinline!
	
	-- setup a read operation
	startreading=(fn) ->
		reading=reading+1
		endstatus=false
		commit=() ->
			return if endstatus
			endstatus=true
			stopreading!
		ok, err=pcall fn, commit
		unless ok
			commit!
			error err
	
	-- setup a write operation
	startwriting=(fn) ->
		writing=true
		endstatus=false
		commit=() ->
			return if endstatus
			exec "COMMIT;"
			endstatus=true
			stopwriting!
		rollback=() ->
			return if endstatus
			exec "ROLLBACK;"
			endstatus=true
			stopwriting!
		exec "BEGIN;"
		ok, err=pcall fn, commit, rollback
		unless ok
			rollback!
			error err
	
	-- transaction start function
	begin=(kind, fn) ->
		error "No such transaction type #{kind}" unless kind=='read' or kind=='write'
		error "No transaction function" unless fn
		error "Illegal type for transaction function #{type fn}" unless 'function'==type fn
		
		if kind=='read'
			if writing or #writequeue!=0
				enqueue readqueue, fn
			else
				startreading fn
		else
			if reading!=0 or writing
				enqueue writequeue, fn
			else
				startwriting fn
	
	begin
