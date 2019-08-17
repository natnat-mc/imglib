SELECT f.name
	FROM formats f
	JOIN images i ON f.id=i.format
	WHERE i.id=:id;
