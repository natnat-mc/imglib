SELECT id, name, permissions, expires
	FROM keys
	WHERE key=:key;
