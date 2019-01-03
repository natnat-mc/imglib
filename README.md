# imglib
An image organization tool

## Is it ready yet?
No

## How does it work?
You feed it images, and tag them. It stores that in a database so that you can find all images that match a list of tags, use a blacklist or basically anything. 
It stores everything it can about an image, like its size, format, add date and fingerprint. Fingerprinting allows for duplicate detection.

## What's under the hood?
This project uses
- Lua >=5.3 with the following modules
	- `lfs`
	- `lsqlite3` or `lsqlite3complete`
	- `luasocket` for daemon mode
- Imagemagick withe `convert` in path

