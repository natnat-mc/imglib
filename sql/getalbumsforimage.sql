SELECT id, name, nsfw, offset
	FROM albums a, albumimage ai
	WHERE ai.album=a.id
		AND ai.image=:image
		AND nsfw=0;
