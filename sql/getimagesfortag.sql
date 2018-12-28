SELECT i.id, i.name, nsfw, f.name AS format, width, height, adddate
	FROM images i, formats f, imagetag it
	WHERE f.id=i.format
		AND it.image=i.id
		AND it.tag=:tag
		AND nsfw=0;
