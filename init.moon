-- patch everything we need
require './patch'

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
