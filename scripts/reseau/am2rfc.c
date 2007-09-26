#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void aide(char ** argv)
{
	fprintf(stderr, "# %s\n", basename(argv[0]));
	fprintf(stderr, "# Apple Mail vers RFC822\n");
	fprintf(stderr, "# © 2006 Guillaume Outters\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Utilisation: par les E/S standard\n");
	fprintf(stderr, "Récupère d'un .emlx la partie RFC822.\n");
	exit(1);
}

int main(int argc, char ** argv)
{
	if(isatty(0)) aide(argv);
	
	int c;
	int n = 0;
	char * m;
	while((c = fgetc(stdin)) && (c >= '0' && c <= '9'))
		if((n = n * 10 + c - '0') > 0x100000) /* Un bon Mo, déjà. */
		{
			fprintf(stderr, "# Trop indigeste. Je refuse.\n");
			exit(1);
		}
	while(c == ' ' && (c = fgetc(stdin))) {}
	if(c != '\n')
	{
		fprintf(stderr, "# Il me fallait des chiffres, suivis d'un retour à la ligne, suivi du message. Ça n'est pas ce que je vois.\n");
		exit(1);
	}
	if(!(m = (char *)malloc(n)))
	{
		fprintf(stderr, "# Le message ne tient pas dans ma mémoire de moineau.\n");
		exit(1);
	}
	if(fread(m, 1, n, stdin) < n)
	{
		fprintf(stderr, "# Message incomplet (plus petit que la taille indiquée).\n");
		exit(1);
	}
	fwrite(m, 1, n, stdout);
}
