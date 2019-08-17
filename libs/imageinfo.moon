fs=require 'fs'
escape=require './escape'

identify="magick identify"
do
	fd=io.popen "which identify", 'r'
	path=(fd\read '*l') or ""
	if path\match "identify$"
		identify=path
	fd\close!

ffmpeg="avconv"
do
	fd=io.popen "which ffmpeg", 'r'
	path=(fd\read '*l') or ""
	if path\match "ffmpeg$"
		ffmpeg=path
	fd\close!

hashprg, hashtype="md5sum", "md5"
do
	try=(ht) ->
		fd=io.popen "which #{ht}"
		path=(fd\read '*l') or ""
		r=false
		if path\match "xxhsum$"
			hashprg, hashtype="#{path} -H0", "xxh32"
			r=true
		fd\close!
		return r
	unless try "xxhsum"
		unless try "xxh32sum"
			try "xxh64sum"

if hashtype!="xxh32"
	io.stderr\write "Warning, using #{hashtype} hashes, which can slow down the program and break compatibility\n"

detectmimetype=(filename) ->
	fd=io.popen "mimetype #{escape filename}", 'r'
	data=fd\read '*l'
	fd\close!
	return data\match "(%S+)/(%S+)$"

detectimagesize=(filename) ->
	fd=io.popen "#{identify} -format '%wx%h' #{escape filename}", 'r'
	data=fd\read '*l'
	fd\close!
	width, height=data\match "^(%d+)x(%d+)$"
	return (tonumber width), (tonumber height)

detectvideosize=(filename) ->
	fd=io.popen "#{ffmpeg} -hide_banner -i #{escape filename} 2>&1", 'r'
	lines=fd\lines!
	local width, height
	while not (width and height)
		line=lines!
		break unless line
		width, height=line\match "Stream.+Video.+ (%d+)x(%d+)"
	fd\close!
	return (tonumber width), (tonumber height)

hash=(filename) ->
	fd=io.popen "#{hashprg} #{escape filename}", 'r'
	data=fd\read '*l'
	fd\close!
	data=data\match "^([a-fA-F0-9]+)%s"
	return "#{hashtype}.#{data\lower!}"

(filename) ->
	info={}
	info.kind, info.format=detectmimetype filename
	if info.kind=='image'
		info.width, info.height=detectimagesize filename
	elseif info.kind=='video'
		info.width, info.height=detectvideosize filename
	else
		error "Unhandled mimetype #{info.kind}/#{info.format}"
	info.hash=hash filename
	return info
