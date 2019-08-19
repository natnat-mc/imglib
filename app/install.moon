-- setup our directory, comrade
fs=require 'fs'

fs.mkdirSync os.getenv 'BASEDIR'
fs.mkdirSync "#{os.getenv 'BASEDIR'}/images"
print "Created directories"

-- setup config file
JSON=require 'json'
fs.writeFileSync "#{os.getenv 'BASEDIR'}/config.json", JSON.stringify {
	data: {
		database: "#{os.getenv 'BASEDIR'}/imgdb.sqlite",
		images: "#{os.getenv 'BASEDIR'}/images",
	},
	server: {
		port: 8080,
		adress: '0.0.0.0'
	},
	randomsize: 128,
	password: "CHANGEME_#{(require '../libs/getrandom') 128}"
}
print "Created config"

-- setup database
sqlite3=require 'lsqlite3'
db=sqlite3.open "#{os.getenv 'BASEDIR'}/imgdb.sqlite", sqlite3.OPEN_READWRITE+sqlite3.OPEN_CREATE
if sqlite3.OK!=db\exec fs.readFileSync './sql/--up--.sql', 'utf8'
	error "Couldn't initialize database"
	db\close!
print "Created database"

-- setup permissions
path=(require '../libs/escape') "#{os.getenv 'BASEDIR'}/imgdb.sqlite"
os.execute "chmod 600 #{path}"
path=(require '../libs/escape') "#{os.getenv 'BASEDIR'}/config.json"
os.execute "chmod 600 #{path}"
path=(require '../libs/escape') "#{os.getenv 'BASEDIR'}/images"
os.execute "chmod 700 #{path}"
print "Setup permissions"
