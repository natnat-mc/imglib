SELECT CASE video WHEN 1 THEN 'video/' ELSE 'image/' END || name
	FROM formats
	WHERE name=:name;
