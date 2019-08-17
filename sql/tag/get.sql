SELECT id, name, description, color, nsfw, imagecount, albumcount
	FROM tags
	WHERE id=:id;
