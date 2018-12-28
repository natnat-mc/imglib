SELECT id, name, color, nsfw
	FROM tags t, albumtag at
	WHERE t.id=at.tag
		AND at.album=:album;
