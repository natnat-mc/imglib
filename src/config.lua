local config={}

config.sqldir='../sql'
config.dbfile=os.getenv 'HOME'..'/imglib.sqlite'
config.imgdir=os.getenv 'HOME'..'/imglib'

return config
