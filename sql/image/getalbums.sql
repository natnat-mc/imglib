SELECT a.id, a.name, a.nsfw
	FROM albums a
	JOIN albumimage l ON l.album=a.id
	WHERE l.image=:id;
