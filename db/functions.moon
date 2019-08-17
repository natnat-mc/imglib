q=(query, field) =>
	if field==nil
		@result_number 0
	elseif (tostring field)\find query
		@result_number 1
	else
		@result_number 0

(db) ->
	db\create_function 'Q', 2, q
