SELECT i.id, i.name, i.description, i.nsfw, i.width, i.height, f.id AS fid, f.name AS fname, f.video AS fvideo, i.adddate, i.checksum
	FROM images i
	JOIN formats f ON i.format=f.id
	WHERE i.id=:id;
