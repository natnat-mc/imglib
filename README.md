# imglib
An image organization tool

## Is it ready yet?
Mostly, the backend works, but not everything has been tested yet so crashes are still possible. Authentication and security aren't implemented yet. The frontend isn't ready yet.

## How does it work?
This tool organizes Images by allowing them to be flagged with Tags, and put in any number of Albums which can also be flagged with Tags.  
Images, Albums and Tags may or may not be flagged as NSFW (Not Safe For Work).

Images have an ID number, a NSFW flag, a format, a size, a checksum used for duplicate detection, an add date and optionally a name and/or description.  
Images can be renamed and have their description altered. Their NSFW flag can also be modified.  
Tags can be added to or removed from Images at any time.

Albums have an ID number, a NSFW flag, a name and an optional description.
Albums can be renamed and have their description altered. Their NSFW flag can also be modified.  
Images and Tags can be added to or removed from Albums at any time.

Tags have an ID number, a NSFW flag, a name, a color and an optional description.  
Tags can have their description and color altered, but their name and NSFW flag are immutable.

A (more or less) [REST API](docs/api.md) is provided to programatically access and alter the database, as well as a web interface (provided in the webui module) and other clients (as separate apps).

## What does it use
This tool is programmed using `luvit`, `mooncake`, `etlua`, `lsqlite3` and `moonscript`. It requires `imagemagick`, `ffmpeg`, `mimetype` (provided by `libfile-mimeinfo-perl`) and `xxhash` to work.

## How do I install it?
- Make sure you're on Linux. Other POSIX platforms (BSD/Cygwin) should work but are not tested
- Install a C compiler, make and the lua5.1 headers
- Clone this repo recursively `git clone --recursive https://github.com/natnat-mc/imglib`
- Install [`luvit`](https://luvit.io/install.html) and [`luarocks`](https://luarocks.org)
- Install `moonscript` (`luarocks install moonscript`)
- Point the `BASEDIR` env variable where the files would be stored (this will be needed at each start)
- Run `./run` to setup the files
- Test the installation
- Stop it with Ctrl+C

### How to start the server as a daemon
- Point the `BASEDIR` env variable
- Run `./start`

### How to read the daemon logs
- Point the `BASEDIR` env variable
- Run `./logs`

### How to stop the daemon
- Point the `BASEDIR` env variable
- Run `./stop`

## What's the license?
For now, imglib is released under the GNU AGPL v3, which means that anyone who can interact with it must be able to access the source code used for this particular instance.
