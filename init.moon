-- patch everything we need
require './patch'

-- update old config file versions
do
	config=require './app/config'
	requireupdate=false
	unless config.randomsize
		config.randomsize, requireupdate=128, true
	unless config.password
		config.password, requireupdate="CHANGEME_#{(require '../libs/getrandom') config.randomsize}", true
	if requireupdate
		(getmetatable config).update!
		print "Updated old config"

-- create a web server
local app
do
	MC=require 'mooncake'
	app=MC\new!

-- install routes
do
	app\use require './api'

-- start web server
do
	config=require './app/config'
	app\start config.server.port, config.server.adress
