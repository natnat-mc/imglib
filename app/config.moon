fs=require 'fs'
JSON=require 'JSON'

cfg=JSON.parse fs.readFileSync "#{os.getenv 'BASEDIR'}/config.json", 'utf8'

setmetatable {}, {
	update: () ->
		fs.writeFileSync "#{os.getenv 'BASEDIR'}/config.json", JSON.stringify cfg
	__index: (k) => cfg[k]
	__newindex: (k, v) => cfg[k]=v
	__tojson: () => JSON.stringify(cfg)
}

-- let's pretend I didn't see this
