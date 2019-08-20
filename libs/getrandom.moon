devurandom=io.open '/dev/urandom', 'r'
unless devurandom
	error "Unable to open /dev/urandom"

hexdigits={'1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', [0]: '0'}

hex=(a) ->
	hi=bit.rshift a, 4
	lo=bit.band a, 15
	return hexdigits[hi]..hexdigits[lo]

(bytes) ->
	str=devurandom\read bytes
	tab=[hex string.byte str\sub i, i for i=1, #str]
	return table.concat tab
