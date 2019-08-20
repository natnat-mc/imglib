DELETE
	FROM keys
	WHERE expires<:now;
