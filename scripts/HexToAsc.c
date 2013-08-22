#include <stdio.h>
#include <stdlib.h>

char equiv[256];

char suivant()
{
	char c;
	if(feof(stdin) || ferror(stdin)) { fflush(stdout); exit(0); }
	while( (c = equiv[getchar()]) < 0) {}
	return(c);
}

int main(argc, argv)
	int argc;
	char ** argv;
{
	int m;
	char c;
	long * ptrl;
	char * ptr;
	
	/* Remplissage de la table d'Žquivalence */
	
	for(m = 0, ptrl = (long *)equiv; m < 256/sizeof(long); m++)
		*ptrl++ = -1;
	for(m = 0, ptr = &equiv['0']; m < 10; m++)
		*ptr++ = m;
	for(m = 10, ptr = &equiv['A']; m < 16; m++)
		*ptr++ = m;
	for(m = 10, ptr = &equiv['a']; m < 16; m++)
		*ptr++ = m;
	
	/* Traitement */
	
	while(1)
		printf("%c", (suivant() << 4) + suivant());
	
	return(0);
}