SELECT i.id, i.name, nsfw, f.name AS format, width, height, adddate
	FROM images i, formats f
	WHERE f.id=i.format
		AND i.id NOT IN (
			SELECT id
				FROM notags
		)
		AND (
			SELECT COUNT(tag)
				FROM imagetag
				WHERE image=i.id
					AND tag IN (
						SELECT id
							FROM yestags
					)
		) = (
			SELECT COUNT(id)
				FROM yestags
		);
