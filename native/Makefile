.PHONY: all clean mrproper

LDFLAGS = -shared
CFLAGS = -I/usr/include/lua5.1/
LIBS = -llua5.1 -pthread
OPTS = -Wall -Wextra -fPIC

CC = gcc
AR = ar
OBJS = main.o
NAME = native

LLIB = $(NAME).so
CLIB = $(NAME).a

all: $(LLIB) $(CLIB)

clean:
	rm -f *.o

mrproper: clean
	rm -f $(LLIB) $(CLIB)

$(LLIB): $(OBJS)
	$(CC) $(OPTS) $(LIBS) $(LDFLAGS) $^ -o $@

$(CLIB): $(OBJS)
	$(AR) cr $@ $^

%.o: %.c
	$(CC) $(OPTS) $(LIBS) $(CFLAGS) -c $^ -o $@
