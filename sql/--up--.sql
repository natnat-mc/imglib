/******************************
 *                            *
 *      PRIMITIVE TYPES       *
 *                            *
 ******************************/

CREATE TABLE formats (
	id INTEGER PRIMARY KEY,
	name VARCHAR(5) UNIQUE NOT NULL,
	video INT(1)
);

CREATE TABLE images (
	id INTEGER PRIMARY KEY,
	name STRING,
	description STRING,
	nsfw INT(1) NOT NULL,
	width INTEGER NOT NULL,
	height INTEGER NOT NULL,
	format INTEGER NOT NULL REFERENCES formats(id) ON DELETE RESTRICT,
	adddate TIMESTAMP NOT NULL,
	checksum STRING
);

CREATE TABLE albums (
	id INTEGER PRIMARY KEY,
	name STRING UNIQUE NOT NULL,
	description STRING,
	nsfw INT(1) NOT NULL,
	imagecount INTEGER DEFAULT 0
);

CREATE TABLE tags (
	id INTEGER PRIMARY KEY,
	name VARCHAR(64) UNIQUE NOT NULL,
	description STRING,
	color CHAR(6) DEFAULT '555555',
	nsfw INT(1) NOT NULL,
	imagecount INTEGER DEFAULT 0,
	albumcount INTEGER DEFAULT 0
);

CREATE TABLE keys (
	id INTEGER PRIMARY KEY,
	name STRING UNIQUE NOT NULL,
	expires TIMESTAMP,
	permissions INTEGER NOT NULL,
	key BLOB NOT NULL
);

/******************************
 *                            *
 *        LINK TABLES         *
 *                            *
 ******************************/
CREATE TABLE imagetag (
	image INTEGER NOT NULL REFERENCES images(id) ON DELETE CASCADE,
	tag INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
	CONSTRAINT U_imagetag UNIQUE(image, tag)
);

CREATE TABLE albumimage (
	album INTEGER NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
	image INTEGER NOT NULL REFERENCES images(id) ON DELETE CASCADE,
	CONSTRAINT U_albumimage UNIQUE(album, image)
);

CREATE TABLE albumtag (
	album INTEGER NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
	tag INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
	CONSTRAINT U_albumtag UNIQUE(album, tag)
);

/******************************
 *                            *
 *        TEMP TABLES         *
 *                            *
 ******************************/
CREATE TABLE yestags (
	id INTEGER
);
CREATE TABLE notags (
	id INTEGER
);
CREATE TABLE anytags (
	id INTEGER
);

/******************************
 *                            *
 *        DEFAULT DATA        *
 *                            *
 ******************************/
BEGIN TRANSACTION;
	INSERT INTO formats(name, video) VALUES('png', 0);
	INSERT INTO formats(name, video) VALUES('jpg', 0);
	INSERT INTO formats(name, video) VALUES('jpeg', 0);
	INSERT INTO formats(name, video) VALUES('gif', 0);
	INSERT INTO formats(name, video) VALUES('bmp', 0);
	INSERT INTO formats(name, video) VALUES('svg', 0);
	INSERT INTO formats(name, video) VALUES('tiff', 0);
	INSERT INTO formats(name, video) VALUES('webm', 1);
	INSERT INTO formats(name, video) VALUES('mp4', 1);
	INSERT INTO formats(name, video) VALUES('mkv', 1);
	INSERT INTO formats(name, video) VALUES('avi', 1);
COMMIT TRANSACTION;
