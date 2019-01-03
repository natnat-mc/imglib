# imglib
An image organization tool

## Is it ready yet?
No

## How does it work?

### Images
Images are stored with:
- a serial ID (unique)
- a format (in a list of allowed formats which can easily updated)
- an optional name (unique)
- a nsfw flag (defaults to no)
- a size (height and width)
- an add date (defaults to the time it is added)

### Albums
Albums are (more or less) ordered collections of images.  
Albums are stored with:
- a serial ID (unique)
- a name (unique)
- a nsfw flag (defaults to no)

### Tags
Tags may be applied to images and albums.  
Tags are stored with:
- a serial ID (unique)
- a color
- a name (unique)
- a nsfw flag (defaults to no)

## Fingerprints
Fingerprints are scaled down images used to detect duplicates and near-duplicates faster than full library checks.  
Fingerprints can and will take a lot of storage space, so it is an opt-in feature.  
Fingerprints are stored with:
- a corresponding image
- a size
- the actual fingerprint

## What's under the hood?
This project uses
- Lua >=5.3 with the following modules
	- `lfs`
	- `lsqlite3` or `lsqlite3complete`
	- `luasocket` for daemon mode
- Imagemagick with the `convert` utility in the path

