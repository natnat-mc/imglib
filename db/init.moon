sqlite3=require 'lsqlite3'
config=require '../app/config'

local db, exec, Statement, TemplatedStatement, begin


do -- load database
	db=sqlite3.open config.data.database, sqlite3.OPEN_READWRITE+sqlite3.OPEN_CREATE+sqlite3.OPEN_FULLMUTEX

do -- create exec function
	exec = (sql) ->
		error db\errmsg! unless sqlite3.OK==db\exec sql

do -- loadable statements
	Statement=require './Statement'
	Statement.db=db
	TemplatedStatement=require './TemplatedStatement'
	TemplatedStatement.db=db

do -- transaction
	begin=(require './begin') exec

do -- custom functions
	(require './functions') db

do -- enable foreign keys
	exec "PRAGMA foreign_keys = ON;"

-- return stuff
{
	:db, :exec
	:Statement, :TemplatedStatement
	:begin
}
