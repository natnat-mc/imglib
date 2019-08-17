fs=require 'fs'
JSON=require 'JSON'

cfg=JSON.parse fs.readFileSync "#{os.getenv 'BASEDIR'}/config.json", 'utf8'

setmetatable {}, {
	update: (data) ->
		cfg=data
		fs.writeFileSync "#{os.getenv 'BASEDIR'}/config.json", JSON.stringify cfg
	__index: (k) => cfg[k]
	__tojson: () => JSON.stringify(cfg)
}

-- let's pretend I didn't see this
