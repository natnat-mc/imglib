local config={}

config.sqldir='../sql'
config.dbfile=os.getenv 'HOME'..'/imglib.sqlite'
config.imgdir=os.getenv 'HOME'..'/imglib'
config.sockfile='/tmp/imglib.sock'

config.features={}
config.features.daemon=true
config.features.fingerprints=false

return config
