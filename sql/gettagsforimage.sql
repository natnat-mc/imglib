SELECT id, name, color, nsfw
	FROM tags t, imagetag it
	WHERE t.id=it.tag
		AND it.image=:image;
