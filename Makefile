.PHONY: all clean mrproper

MOON_FILES = $(wildcard api/*.moon) $(wildcard app/*.moon) $(wildcard db/*.moon) $(wildcard libs/*.moon) init.moon
LUA_FILES = $(patsubst %.moon, %.lua, $(MOON_FILES))

all: $(LUA_FILES) native/native.so daemonize/daemonize

clean:
	rm -f $(LUA_FILES)
	(cd native && make clean)
	(cd daemonize && make clean)

mrproper: clean
	(cd native && make mrproper)
	(cd daemonize && make mrproper)

%.lua: %.moon
	moonc $<

native/native.so: native/main.c
	(cd native && make)

daemonize/daemonize: daemonize/main.c
	(cd daemonize && make)
	
