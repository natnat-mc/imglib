SELECT image, size, fingerprint, diff
	FROM (
		SELECT image, size, fingerprint, delta(fingerprint, :original) AS diff
			FROM fingerprints
		)
	WHERE diff<:maxdelta
	ORDER BY diff ASC
	LIMIT :maxn;
