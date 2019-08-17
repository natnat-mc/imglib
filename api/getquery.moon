(query, t, ornil) ->
	t=t\lower!
	if ornil and query==nil
		return nil
	if t=='string'
		error "multiple values for string" if 'table'==type query
		error "no string given" unless query
		return query
	if t=='string:hex'
		error "multiple values for string:hex" if 'table'==type query
		error "no string given" unless query
		error "wrong format for string:hex #{query}" unless query\match "^[0-9a-fA-F]+$"
		return query
	if t=='string:color'
		error "multiple values for string:color" if 'table'==type query
		error "no string given" unless query
		error "wrong format for string:color #{query}" unless #query==6 and query\match "^[0-9a-fA-F]+$"
		return query
	if t=='number'
		n=tonumber query
		error "wrong format for number #{query}" unless n
		return n
	if t=='int'
		n=tonumber query
		error "wrong format for int #{query}" unless n and query\match "^[0-9]+$"
		return n
	if t=='list'
		return {query} if 'table'!=type query
		return query
	if t=='boolean'
		if query=='1' or query=='true' or query=='yes'
			return true
		elseif query=='0' or query=='false' or query=='no'
			return false
		error "wrong format for boolean: #{query}"
	if t=='boolean|\'any\''
		if query=='1' or query=='true' or query=='yes'
			return true
		elseif query=='0' or query=='false' or query=='no'
			return false
		elseif query=='any'
			return 'any'
		error "wrong format for boolean|\'any\': #{query}"
	if t=='csv'
		error "multiple values for csv" if 'table'==type query
		a={}
		n=1
		s=''
		q, e=false, false
		for i=1, #query
			c=query\sub(i, i)
			if c==',' and not q
				error "wrong format for csv: #{query}" unless #s!=0
				a[n], n, s=s, n+1, ''
				q, e=false, false
			elseif c=='"'
				if q and not e
					q, e=false, true
				elseif not q
					s=s..c if e
					q, e=true, false
			else
				s=s..c
		a[n]=s
		error "wrong format for csv: #{query}" unless #s!=0
		return a
