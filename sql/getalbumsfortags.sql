SELECT a.id, a.name, nsfw
	FROM albums a
	WHERE a.id NOT IN (
			SELECT at.album
				FROM albumtag at, notags n
				WHERE at.tag=n.id
		)
		AND (
			SELECT COUNT(tag)
				FROM albumtag
				WHERE album=a.id
					AND tag IN (
						SELECT id
							FROM yestags
					)
		) = (
			SELECT COUNT(id)
				FROM yestags
		)
		AND nsfw=0;
