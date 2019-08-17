SELECT i.id
	FROM images i, formats f
	WHERE
		i.format=f.id AND
		f.name=:format AND
		i.height=:height AND
		i.width=:width AND
		i.checksum=:checksum;
