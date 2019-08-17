#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>

#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <dlfcn.h>

#define LUAFN static int
int luaopen_native(lua_State*); // forward declaration

//code from https://stackoverflow.com/questions/24259640/writing-a-full-buffer-using-write-system-call
static int writen(const int sd, const char * b, const size_t s, const int retry_on_interrupt)
{
	size_t n = s;
	while (0 < n)
	{
		ssize_t result = write(sd, b, n);
		if (-1 == result)
		{
			if ((retry_on_interrupt && (errno == EINTR)) || (errno == EWOULDBLOCK) || (errno == EAGAIN))
			{
				continue;
			}
			else
			{
				break;
			}
		}
		
		n -= result;
		b += result;
	}
	
	return (0 < n) ?-1 :0;
}

LUAFN native_pipe(lua_State *L) {
	int fds[2];
	if(pipe(fds)==-1) {
		luaL_error(L, "failed to create pipe");
	}
	lua_pushnumber(L, fds[0]);
	lua_pushnumber(L, fds[1]);
	return 2;
}

LUAFN native_write(lua_State *L) {
	int fd=luaL_checknumber(L, 1);
	size_t len=0;
	const char* str=luaL_checklstring(L, 2, &len);
	if(writen(fd, str, len, 1)==-1) {
		luaL_error(L, "failed to write");
	}
	return 0;
}

LUAFN native_close(lua_State *L) {
	int fd=luaL_checknumber(L, 1);
	if(close(fd)==-1) {
		luaL_error(L, "failed to close");
	}
	return 0;
}

LUAFN native_read(lua_State *L) {
	int fd=luaL_checknumber(L, 1);
	int len=luaL_optnumber(L, 2, 1);
	char* buf=(char*) malloc(len);
	if(!buf) {
		luaL_error(L, "failed to allocate buffer");
	}
	int readlen=read(fd, buf, len);
	if(readlen==-1) {
		luaL_error(L, "failed to read");
	}
	lua_pushlstring(L, buf, readlen);
	free(buf);
	return 1;
}

LUAFN native_canread(lua_State *L) {
	int fd=luaL_checknumber(L, 1);
	fd_set rfds;
	struct timeval tv;
	FD_ZERO(&rfds);
	FD_SET(fd, &rfds);
	tv.tv_sec=0;
	tv.tv_usec=0;
	int ret=select(fd+1, &rfds, NULL, NULL, &tv);
	if(ret==-1) {
		return luaL_error(L, "error with select");
	} else if(ret) {
		lua_pushnumber(L, ret);
		return 1;
	} else {
		lua_pushboolean(L, 0);
		return 1;
	}
}

typedef struct {
	pthread_t id;
	lua_State *L;
} native_thread_t;

static void* thread_body(void* state) {
	lua_State *L=((native_thread_t*) state)->L;
	int argc=lua_gettop(L)-1;
	if(lua_pcall(L, argc, 0, 0)) {
		fprintf(stderr, "Uncaught exception: %s", luaL_checkstring(L, 1));
	}
	lua_close(L);
	free(state);
	return (void*) 0;
}

#define try(fmt, var) do{ \
	sprintf(buf, fmt, var); \
	int status=luaL_loadfile(L, buf); \
	if(!status) { \
		return 1;\
	} \
} while(0)
static int luvit_searcher(lua_State *L) {
	// retrieve name and lowercase name
	const char* name=luaL_checkstring(L, 1);
	lua_getglobal(L, "string");
	lua_getfield(L, -1, "lower");
	lua_pushstring(L, name);
	lua_call(L, 1, 1);
	lua_insert(L, 2);
	lua_settop(L, 2);
	const char* lowername=luaL_checkstring(L, 2);
	
	char buf[256];
	
	// try C code
	luaL_loadstring(L, "local ffi=require 'ffi'\n local name=select(1, ...)\n return 'deps/'..name..'/built/'..ffi.os..'-'..ffi.arch..'/'..name..'.so'");
	lua_pushstring(L, name);
	lua_call(L, 1, 1);
	const char* filename=luaL_checkstring(L, -1);
	void* handle=dlopen(filename, RTLD_LAZY);
	if(handle) {
		sprintf(buf, "luaopen_%s", name);
		void* symbol=dlsym(handle, buf);
		if(symbol) {
			lua_pushcfunction(L, symbol);
			return 1;
		}
	}
	
	
	// try lua code
	try("deps/%s", name);
	try("deps/%s.lua", name);
	try("deps/%s/init.lua", name);
	try("deps/%s", lowername);
	try("deps/%s.lua", lowername);
	try("deps/%s/init.lua", lowername);
	
	lua_pushstring(L, "\n\tnot in deps");
	return 1;
}

void luaL_openlibs(lua_State*); // apparently, it's not exposed

LUAFN native_startthread(lua_State *L) {
	//BEGIN dump arg1 to string
	int argc=lua_gettop(L); // stack: argc
	// move the function to the top of the stack
	for(int i=1; i<argc; i++) {
		lua_insert(L, 1);
	}
	
	if(lua_isfunction(L, -1)) {
		// create string.dump under it
		lua_getglobal(L, "string"); // stack: argc+1
		lua_getfield(L, -1, "dump"); // stack: argc+2
		lua_insert(L, -3); // stack: argc+2
		lua_settop(L, argc+1); // stack: argc+1
		if(lua_pcall(L, 1, 1, 0)) { // stack: argc
			return luaL_error(L, "failed to dump the thread function");
		}
	} else if(!lua_isstring(L, -1)) { // stack: argc
		return luaL_argerror(L, 1, "expected string or function");
	}
	
	size_t len;
	const char* code=luaL_checklstring(L, -1, &len);
	//END dump arg1 to string
	
	//BEGIN make sure all arguments are serializable
	for(int i=1; i<argc; i++) {
		int type=lua_type(L, i);
		if(type!=LUA_TNIL && type!=LUA_TNUMBER && type!=LUA_TBOOLEAN && type!=LUA_TSTRING && type!=LUA_TLIGHTUSERDATA) {
			return luaL_argerror(L, i, "non-serializable type");
		}
	}
	//END make sure all arguments are serializable
	
	//BEGIN create state
	// create the state itself
	lua_State *K=luaL_newstate();
	luaL_openlibs(K);
	
	// setup all the libs we need
	lua_getglobal(K, "package");
	lua_getfield(K, 1, "preload");
	lua_pushcfunction(K, luaopen_native);
	lua_setfield(K, 2, "native");
	luaL_loadstring(K, "return package.loaders, #package.loaders");
	lua_call(K, 0, 2);
	lua_pushcfunction(K, luvit_searcher);
	lua_settable(K, -3);
	lua_settop(K, 0);
	
	// load the main function
	if(luaL_loadbuffer(K, code, len, "thread-main")) { // stack: 1
		lua_close(K);
		return luaL_error(L, "failed to create function: %s", luaL_checkstring(K, -1));
	}
	
	// load arguments
	for(int i=1; i<argc; i++) {
		switch(lua_type(L, i)) {
			case LUA_TNIL:
				lua_pushnil(K);
				break;
			
			case LUA_TNUMBER:
				lua_pushnumber(K, luaL_checknumber(L, i));
				break;
			
			case LUA_TBOOLEAN:
				lua_pushboolean(K, lua_toboolean(L, i));
				break;
			
			case LUA_TSTRING:
			{
				size_t len;
				const char* str=luaL_checklstring(L, i, &len);
				lua_pushlstring(K, str, len);
				break;
			}
			
			case LUA_TLIGHTUSERDATA:
				lua_pushlightuserdata(K, lua_touserdata(L, i));
				break;
		}
	}
	//END create state
	
	//BEGIN create thread
	// create the structure to hold all the info we need
	native_thread_t* threaddata=(native_thread_t*) malloc(sizeof(native_thread_t));
	if(!threaddata) {
		lua_close(K);
		return luaL_error(L, "failed to allocate data");
	}
	threaddata->L=K;
	
	// actually create the thread
	pthread_attr_t attr;
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
	if(pthread_create(&threaddata->id, &attr, thread_body, threaddata)) {
		free(threaddata);
		pthread_attr_destroy(&attr);
		lua_close(K);
		return luaL_error(L, "failed to create thread");
	}
	pthread_attr_destroy(&attr);
	//END create thread
	return 0;
}

int luaopen_native(lua_State *L) {
	lua_settop(L, 0); // stack: 0
	lua_newtable(L); // stack: 1
	lua_pushcfunction(L, native_pipe); // stack: 2
	lua_setfield(L, 1, "pipe"); // stack: 1
	lua_pushcfunction(L, native_write); // stack: 2
	lua_setfield(L, 1, "write"); // stack: 1
	lua_pushcfunction(L, native_close); // stack: 2
	lua_setfield(L, 1, "close"); // stack: 1
	lua_pushcfunction(L, native_read); // stack: 2
	lua_setfield(L, 1, "read"); // stack: 1
	lua_pushcfunction(L, native_canread); // stack: 2
	lua_setfield(L, 1, "canread"); // stack: 1
	lua_pushcfunction(L, native_startthread); // stack: 2
	lua_setfield(L, 1, "startthread"); // stack: 1
	return 1;
}
