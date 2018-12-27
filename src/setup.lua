-- load everything
local util=require 'util'
local config=require 'config'
local fs=require 'lfs'
local sqlite=util.tryrequire 'lsqlite3complete' or require 'lsqlite3'

-- destroy the database if it exists
if fs.attributes(config.dbfile) then
--	if util.confirm("Delete old database", false) then
	if true then
		os.remove(config.dbfile)
	else
		os.exit(1)
	end
end

-- create a new database
local db=sqlite.open(config.dbfile)
-- create the actual folder
lfs.mkdir(config.imgdir)

-- execute a statement
function tryexec(stat)
	local a, b, c=util.tryexec(db, stat)
	print(stat)
	if a then
		print('OK')
	else
		print(b, c)
	end
	print()
	return a
end

-- create 'tags' table
tryexec [[
CREATE TABLE tags (
	id INTEGER PRIMARY KEY,
	name VARCHAR(64) UNIQUE NOT NULL,
	color CHAR(6) DEFAULT '555555',
	nsfw INT(1) DEFAULT 0
);]]
-- create 'formats' table
tryexec [[
CREATE TABLE formats (
	id INTEGER PRIMARY KEY,
	name VARCHAR(5) UNIQUE NOT NULL
);]]
-- create 'images' table
tryexec [[
CREATE TABLE images (
	id INTEGER PRIMARY KEY,
	name STRING,
	nsfw INT(1) DEFAULT 0,
	height INTEGER NOT NULL,
	width INTEGER NOT NULL,
	format INTEGER NOT NULL REFERENCES formats(id),
	adddate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);]]
-- create 'imagetag' table
tryexec [[
CREATE TABLE imagetag (
	image INTEGER NOT NULL REFERENCES images(id),
	tag INTEGER NOT NULL REFERENCES tags(id)
);]]
-- create 'fingerprints' table
tryexec [[
CREATE TABLE fingerprints (
	image INTEGER NOT NULL REFERENCES images(id),
	size INT(4) NOT NULL,
	fingerprint BLOB NON NULL,

	CONSTRAINT PK_fingerprint PRIMARY KEY(image, size)
);]]
--create basic formats
tryexec [[
INSERT INTO formats(name) VALUES('png');
INSERT INTO formats(name) VALUES('jpg');
INSERT INTO formats(name) VALUES('gif');
INSERT INTO formats(name) VALUES('bmp');
INSERT INTO formats(name) VALUES('svg');
INSERT INTO formats(name) VALUES('tiff');]]

-- do some tests
tryexec [[
INSERT INTO tags(name) VALUES('color');
INSERT INTO tags(name, nsfw) VALUES('nsfw', 1);
INSERT INTO TAGS(name, color) VALUES('red', 'ff0000');
INSERT INTO images(name, height, width, format) VALUES('test', 600, 800, 'png');
INSERT INTO images(name, height, width, format, nsfw) VALUES('nope', 123, 455, 'png', 1);
INSERT INTO imagetag(image, tag) VALUES(1, 1);
INSERT INTO imagetag(image, tag) VALUES(2, 2);]]

util.tabselect(db, [[
SELECT id, name, color, nsfw FROM tags;
]], {'id', 'name', 'color', 'nsfw'})

util.tabselect(db, [[
SELECT id, name, nsfw, height, width, format, adddate FROM images;
]], {'id', 'name', 'nsfw', 'height', 'width', 'format', 'adddate'})

util.tabselect(db, [[
SELECT id, name FROM formats;
]], {'id', 'name'})

util.tabselect(db, [[
SELECT i.name AS image, t.name AS tag, i.nsfw AS nsfw
FROM images i, tags t, imagetag it
WHERE i.id=it.image AND t.id=it.tag;
]], {'image', 'tag', 'nsfw'})

-- close the database
db:close()

