db=require '../db'
authenticate=require './authenticate'
getquery=require './getquery'

convert=(line) -> {id: line.id, name: line.name, nsfw: line.nsfw==1, imagecount: line.imagecount, albumcount: line.albumcount}

(req, res) ->
	return unless authenticate req, res, {'read'}
	
	import q, name, color, nsfw, minimagecount, maximagecount, minalbumcount, maxalbumcount from req.query
	ok, err=pcall () ->
		q=getquery q, 'string', true
		name=getquery name, 'string', true
		color=getquery color, 'string:hex', true
		nsfw=getquery nsfw, 'boolean|\'any\'', true
		nsfw=nil if nsfw=='any'
		minimagecount=getquery minimagecount, 'int', true
		maximagecount=getquery maximagecount, 'int', true
		minalbumcount=getquery minalbumcount, 'int', true
		maxalbumcount=getquery maxalbumcount, 'int', true
		error "invalid image count boundaires" if minimagecount and maximagecount and maximagecount<minimagecount
		error "invalid album count boundaires" if minalbumcount and maxalbumcount and maxalbumcount<minalbumcount
	return res\status(400)\json {:ok, :err} unless ok
	
	params={:q, :name, :color, :nsfw, :minimagecount, :maximagecount, :minalbumcount, :maxalbumcount}
	db.begin 'read', (done) ->
		listtags=db.TemplatedStatement.get 'tag/list', {k, true for k in pairs params}
		
		res\streamStatement listtags, params, convert, done
