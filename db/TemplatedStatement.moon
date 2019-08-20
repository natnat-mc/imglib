Statement=require './Statement'
fs=require 'fs'
etlua=require 'mooncake/libs/etlua'

class TemplatedStatement extends Statement
	statements={}
	@get: (name, params) ->
		statements[name]={} unless statements[name]
		keys=[k for k in pairs params]
		table.sort keys
		kv=["#{k}=#{params[k]}" for k in *keys]
		paramlist=table.concat kv, ','
		statements[name][paramlist]=@ name, params unless statements[name][paramlist]
		return statements[name][paramlist]
	
	new: (name, params) =>
		@readypool={}
		@code=fs.readFileSync "sql/#{name}.sql.etlua", 'utf8'
		error "Couldn't read statement #{name}" unless @code
		ok, @code, err=pcall etlua.render, @code, params
		error "Error rendering statement #{name}" unless ok
		error "Couldn't apply statement parameters: #{err} to statement #{name}" unless @code
		@code=@code\gsub("AND%s+1", '')\gsub("WHERE%s+1", '')\gsub "\n%s+\n" , '\n'
		@_create!
	
	@iterate: (name, params, vals) -> (@.get name, params)\iterate vals
	@iterate2: (name, params, vals, fn) -> (@.get name, params)\iterate2 vals, fn
	@getrow: (name, params, vals) -> (@.get name, params)\getrow vals
	@getsingle: (name, params, vals) -> (@.get name, params)\getsingle vals
	@has: (name, params, vals) -> (@.get name, params)\has vals
	@execute: (name, params, vals) -> (@.get name, params)\execute vals
	@update: (name, params, vals) -> (@.get name, params)\update vals
	@insert: (name, params, vals) -> (@.get name, params)\insert vals
