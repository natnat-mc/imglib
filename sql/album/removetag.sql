DELETE
	FROM albumtag
	WHERE tag=:tag
		AND album=:album;
