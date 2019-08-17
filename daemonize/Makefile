.PHONY: all clean mrproper

LDFLAGS = 
CFLAGS = 
LIBS = 
OPTS = -Wall

CC = gcc
AR = ar
OBJS = main.o
NAME = daemonize

all: $(NAME) $(CLIB)

clean:
	rm -f *.o

mrproper: clean
	rm -f $(NAME)

$(NAME): $(OBJS)
	$(CC) $(OPTS) $(LIBS) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(OPTS) $(LIBS) $(CFLAGS) -c $^ -o $@
