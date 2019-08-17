appname="Imglib"
version="0.1"

local branch, commit, url, shorturl

-- fetch the commit hash
do
	fd=io.popen 'git rev-parse HEAD'
	commit=fd\read '*l'
	fd\close!

-- fetch the git branch
do if commit
	fd=io.popen 'git branch'
	for br in fd\lines!
		if '+'==br\sub 1, 1
			branch=br\sub 3
			break
	branch='master' unless branch
	fd\close!

-- fetch the remote git URL if we can
do if commit
	fd=io.popen 'git remote get-url origin'
	originurl=fd\read '*l'
	fd\close!
	do
		ghurl=originurl\match 'github%.com[:/](.+).git'
		url="https://github.com/#{ghurl}" if ghurl
	do unless url
		glurl=originurl\match 'gitlab%.com[:/](.+).git'
		url="https://gitlab.com/#{glurl}" if glurl
	shorturl=url\gsub 'https?://', '' if url

{
	:appname, :version,
	:commit,
	:branch,
	:url, :shorturl
}
