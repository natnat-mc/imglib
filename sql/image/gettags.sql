SELECT t.id, t.name, t.color, t.nsfw, t.imagecount, t.albumcount
	FROM tags t
	JOIN imagetag l ON l.tag=t.id
	WHERE l.image=:id;
