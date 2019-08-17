DELETE
	FROM imagetag
	WHERE image=:image
		AND tag=:tag;
