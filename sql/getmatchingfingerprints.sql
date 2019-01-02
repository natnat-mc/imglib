SELECT image, size, fingerprint, diff
	FROM (
		SELECT image, size, fingerprint, imagedelta(fingerprint, :original) AS diff
			FROM fingerprints
		)
	WHERE diff<:maxdelta
	ORDER BY diff ASC
	LIMIT :maxn;
