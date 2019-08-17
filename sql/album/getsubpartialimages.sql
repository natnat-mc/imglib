SELECT i.id, i.name, i.nsfw, i.width, i.height, f.id AS fid, f.name AS fname, f.video AS fvideo
	FROM images i
	JOIN formats f ON f.id=i.format
	JOIN albumimage ai ON i.id=ai.image
	WHERE ai.album=:id
	LIMIT 10;
