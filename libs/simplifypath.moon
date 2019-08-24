(path) ->
	startslash, endslash=('/'==path\sub 1, 1), ('/'==path\sub -1, -1)
	plist=[part for part in path\gmatch '[^/]+']
	i=1
	while i<=#plist
		if plist[i]=='..'
			table.remove plist, i
			table.remove plist, i-1
			i-=1
		elseif plist[i]=='.'
			table.remove plist, i
		else
			i+=1
	for i=1, #plist-1
		plist[i]..='/'
	return (startslash and '/' or '')..(table.concat plist)..(endslash and '/' or '')
