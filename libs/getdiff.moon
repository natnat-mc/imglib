(old, new) ->
	removed, added={}, {}
	oi, ni=1, 1
	ol, nl=#old, #new
	while oi<=ol and ni<=nl
		o, n=old[oi], new[ni]
		if o==n then
			oi, ni=oi+1, ni+1
		elseif o>n
			table.insert added, n
			ni=ni+1
		elseif o<n
			table.insert removed, o
			oi=oi+1
		else
			error "What the fuck"
	if ni<=nl
		for i=ni, nl
			table.insert added, new[i]
	if oi<=ol
		for i=oi, ol
			table.insert removed, old[i]
	return removed, added
