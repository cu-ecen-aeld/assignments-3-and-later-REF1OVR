#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <string.h>

int main(int argc, char *argv[]){
	// Open a connection to the syslog server
	openlog("writer", LOG_PID|LOG_CONS, LOG_USER);

	// Check for correct argument count
	if(argc < 3){
		syslog(LOG_ERR, "Error: Writer function requires two arguments. Usage: %s </path/to/file> <string>", argv[0]);
		closelog();		// Optional according to man page
		return 1;
	}

	// Extract arguments to variables
	char *writefile = argv[1];
	char *writestr = argv[2];

	// Attempt to open file and check for errors
	FILE *fp = fopen(writefile, "w");
	if(fp == NULL){
		syslog(LOG_ERR, "Failed to open file: %s", writefile);
		closelog();		// Optional according to man page
		return 1;
	}

	// Write string to file and check for errors
	if(fputs(writestr, fp) == EOF){
		syslog(LOG_ERR, "Failed to write file: %s", writefile);
		fclose(fp);
		closelog();		// Optional according to man page
		return 1;
    }

	syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);

	// Close the file and check for errors
	if(fclose(fp) != 0){
		syslog(LOG_ERR, "Error occurred while closing file: %s", writefile);
		closelog();		// Optional according to man page
		return 1;
	}

	// Close connection to the syslog server
	closelog();			// Optional according to man page

	return 0;
}
