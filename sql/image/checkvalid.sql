SELECT COUNT(1)
	FROM images i, formats f
	WHERE
		i.format=f.id AND
		i.id=:id AND
		f.name=:format AND
		i.checksum=:checksum;
-- everyone is valid except me!
