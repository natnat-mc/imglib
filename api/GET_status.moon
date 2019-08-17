db=require '../db'
authenticate=require './authenticate'

countimages=db.Statement.get 'count/images'
countalbums=db.Statement.get 'count/albums'
counttags=db.Statement.get 'count/tags'
countformats=db.Statement.get 'count/formats'

(req, res) ->
	return unless authenticate req, res, {}
	db.begin 'read', (done) ->
		res\json {ok: true, res: {
				imgcount: countimages\getsingle!,
				albumcount: countalbums\getsingle!,
				tagcount: counttags\getsingle!,
				formatcount: countformats\getsingle!
			}
		}
		done!
