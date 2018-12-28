SELECT id, name, nsfw
	FROM albums a, albumtag at
	WHERE a.id=at.album
		AND at.tag=:tag
		AND nsfw=0;
