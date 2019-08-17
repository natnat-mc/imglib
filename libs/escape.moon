(str) ->
	if str\match "^[a-zA-Z0-9._/-]+$"
		return str
	return "\"#{str\gsub("\\", "\\\\")\gsub("\"", "\\\"")}\""
