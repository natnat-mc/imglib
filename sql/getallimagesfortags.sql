SELECT i.id, i.name, nsfw, f.name AS format, width, height, adddate
	FROM images i, formats f
	WHERE f.id=i.format
		AND i.id NOT IN (
			SELECT it.image
				FROM notags n, imagetag it
				WHERE n.id=it.tag
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
