db=require '../db'
authenticate=require './authenticate'

listformats=db.Statement.get 'format/list'

convert=(line) -> {id: line.id, name: line.name, video: line.video==1}

(req, res) ->
	return unless authenticate req, res, {'read'}
	db.begin 'read', (done) ->
		res\streamStatement listformats, nil, convert, done
