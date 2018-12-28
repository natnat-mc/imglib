SELECT i.id, i.name, nsfw, f.name AS format, width, height, adddate, ai.offset
	FROM images i, formats f, albumimage ai
	WHERE f.id=i.format
		AND ai.image=i.id
		AND ai.album=:album
		AND nsfw=0;
