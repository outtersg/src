#include <errno.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

int main(int argc, char ** argv)
{
	struct stat infos;
	struct tm * date;
	char sepChamps, sepEntrees;
	char aff[0x100];
	
	sepEntrees = '\n';
	sepChamps = ' ';
	while(*++argv)
		if(strcmp(*argv, "-0") == 0)
		{
			sepEntrees = 0;
			sepChamps = 0;
		}
		else if(stat(*argv, &infos) == 0)
		{
			date = localtime(&infos.st_mtimespec.tv_sec);
			strftime(aff, 0x00ff, "%Y%m%d%H%M%S", date);
			fprintf(stdout, "%s%9.9d%c%s%c", aff, infos.st_mtimespec.tv_nsec, sepChamps, *argv, sepEntrees);
		}
		else
			fprintf(stderr, "### %s: %s.\n", *argv, strerror(errno));
}