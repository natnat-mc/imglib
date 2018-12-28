SELECT i.id, i.name, nsfw, f.name AS format, width, height, adddate
	FROM images i, formats f
	WHERE f.id=i.format
		AND i.name=:name;
