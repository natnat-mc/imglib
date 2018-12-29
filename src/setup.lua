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
	name STRING UNIQUE,
	nsfw INT(1) DEFAULT 0,
	height INTEGER NOT NULL CHECK(height>0),
	width INTEGER NOT NULL CHECK(width>0),
	format INTEGER NOT NULL REFERENCES formats(id),
	adddate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);]]
-- create 'albums' table
tryexec [[
CREATE TABLE albums (
	id INTEGER PRIMARY KEY,
	name STRING UNIQUE,
	nsfw INT(1) DEFAULT 0
);]]
-- create 'imagetag' table
tryexec [[
CREATE TABLE imagetag (
	image INTEGER NOT NULL REFERENCES images(id),
	tag INTEGER NOT NULL REFERENCES tags(id),
	CONSTRAINT PK_imagetag PRIMARY KEY(image, tag)
);]]
-- create 'albumtag' table
tryexec [[
CREATE TABLE albumtag (
	album INTEGER NOT NULL REFERENCES albums(id),
	tag INTEGER NOT NULL REFERENCES tags(id),
	CONSTRAINT PK_albumtag PRIMARY KEY(album, tag)
);]]
-- create 'albumimage' table
tryexec [[
CREATE TABLE albumimage (
	album INTEGER NOT NULL REFERENCES albums(id),
	image INTEGER NOT NULL REFERENCES images(id),
	offset INTEGER NOT NULL CHECK(offset>=1),
	CONSTRAINT PK_albumimage PRIMARY KEY(album, image)
);]]
-- create 'fingerprints' table
tryexec [[
CREATE TABLE fingerprints (
	image INTEGER NOT NULL REFERENCES images(id),
	size INT(4) NOT NULL,
	fingerprint BLOB NOT NULL,
	CONSTRAINT PK_fingerprint PRIMARY KEY(image, size)
);]]
-- enable foreign keys
tryexec [[PRAGMA foreign_keys=ON;]]
--create basic formats
tryexec [[
BEGIN TRANSACTION;
	INSERT INTO formats(name) VALUES('png');
	INSERT INTO formats(name) VALUES('jpg');
	INSERT INTO formats(name) VALUES('gif');
	INSERT INTO formats(name) VALUES('bmp');
	INSERT INTO formats(name) VALUES('svg');
	INSERT INTO formats(name) VALUES('tiff');
COMMIT TRANSACTION;]]

-- close the database
db:close()

