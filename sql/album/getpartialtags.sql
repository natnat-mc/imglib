SELECT t.id, t.name, t.color, t.nsfw, t.imagecount, t.albumcount
	FROM tags t
	JOIN albumtag l ON t.id=l.tag
	WHERE l.album=:id
	LIMIT 10;
