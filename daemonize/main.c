#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <dlfcn.h>
#include <limits.h>

int main(int argc, char** argv) {
	// run ourselves in background
	pid_t pid=fork();
	if(pid<0) { // we couldn't fork
		fprintf(stderr, "Couldn't fork\n");
		exit(1);
	} else if(pid>0) { // we're the parent
		exit(0);
	}
	
	// get ourselves a process tree on our own
	setsid();
	
	// make sure we're the only one
	char buf[PATH_MAX];
	sprintf(buf, "%s/lockfile", getenv("BASEDIR"));
	int lock=open(buf, O_RDWR|O_CREAT, 0640);
	if(lock<0) { // failed to open the lock
		fprintf(stderr, "Couldn't open lock\n");
		exit(1);
	}
	if(lockf(lock, F_TLOCK, 0)<0) { // we're not unique
		fprintf(stderr, "Daemon already running\n");
		exit(0);
	}
	
	// write our PID to the lockfile for our start/stop scripts
	sprintf(buf, "%d", getpid());
	write(lock, buf, strlen(buf));
	ftruncate(lock, strlen(buf));
	
	// we're now officialy a daemon
	return execvp(argv[1], argv+1);
}
