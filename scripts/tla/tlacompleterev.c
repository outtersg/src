#include <stdio.h>

/* Découpe la chaîne produite en entrée en une ou deux chaînes, sur un slash,
 * puis, à l'intérieur de chacune des sous-chaînes, sur les double-tirets. Les
 * tableaux sont clos par un NULL; le tableau renvoyé doit être désalloué (le
 * bloc-mémoire contient tous les sous-tableaux et chaînes, un seul free()
 * suffit). */

char *** decouper(char * chaine)
{
	int taille;
	int octets;
	char * ptr;
	char * sep;
	char ** ptrptr;
	char *** ptrptrptr;
	char *** retour;
	
	/* Première passe pour calculer la place à allouer. */
	
	taille = strlen(chaine);
	octets = 0;
	octets += sizeof(char **); /* Pointeur sur le sous-tableau "module, branche, version, révision". */
	octets += sizeof(char **); /* Au moins un élément. */
	for(ptr = strstr(chaine, "--"); ptr; ptr = strstr(ptr + 2, "--"))
		octets += sizeof(char **); /* Élément. */
	if((sep = strchr(chaine, '/')))
	{
		octets += sizeof(char **); /* Pointeur sur le découpage avant-slash. */
		octets += sizeof(char **); /* Un "élément" tel que calculé au-dessus se retrouve découpé par le slash en deux. */
		octets += sizeof(char **); /* NULL en fin de tableau. */
	}
	octets += sizeof(char **); /* NULL en fin de tableau d'éléments. */
	octets += sizeof(char **); /* NULL en fin de tableau principal. */
	octets += taille * sizeof(char) + 1;
	
	/* Recopie, remplissage. */
	
	ptr = (char *)(ptrptrptr = retour = (char ***)malloc(octets));
	ptrptr = (char **)&ptrptrptr[2]; /* Un pointeur, suivi d'un NULL, et ensuite on place nos sous-tableaux. */
	strcpy(ptr = &ptr[octets - (taille * sizeof(char) + 1)], chaine);
	if(sep)
	{
		sep = &ptr[sep - chaine];
		*sep = 0;
		
		++((char ***)ptrptr); /* On décale tout, car on insère un pointeur avant. */
		*ptrptrptr++ = ptrptr;
		
		*ptrptr++ = ptr;
		for(ptr = strstr(ptr, "--"); ptr; ptr = strstr(ptr, "--"))
		{
			*ptr = 0;
			*ptrptr++ = (ptr += 2);
		}
		*ptrptr++ = NULL;
		
		ptr = sep + 1;
	}
	
	*ptrptrptr++ = ptrptr;
	*ptrptr++ = ptr;
	for(ptr = strstr(ptr, "--"); ptr; ptr = strstr(ptr, "--"))
	{
		*ptr = 0;
		*ptrptr++ = (ptr += 2);
	}
	*ptrptr++ = NULL;
	
	*ptrptrptr++ = NULL;
	
	return retour;
}

void afficherDecoupe(char ** decoupe, int jusquA)
{
	char * format = "%s";
	int pos = 0;
	while(*decoupe && pos != jusquA) /* Différent et non inférieur, car jusquA peut valoir -1. */
	{
		fprintf(stdout, format, *decoupe);
		format = "--%s";
		++decoupe;
		++pos;
	}
}

int main(int argc, char ** argv)
{
	char *** decoupe1;
	char *** decoupe2;
	char ** ptrptr;
	int n1, n2;
	
	if(argc != 3)
	{
		char * ptr;
		ptr = (ptr = strrchr(argv[0], '/')) ? ptr + 1 : argv[0];
		fprintf(stderr, "# %s\n", ptr);
		fprintf(stderr, "# Modification d'une rev Arch par sa fin\n");
		fprintf(stderr, "# © Guillaume Outters 2004\n");
		fprintf(stderr, "\n");
		fprintf(stderr, "Utilisation: %s <révision complète> <fin de révision>\n", ptr);
		fprintf(stderr, "  <révision complète>: numéro complet d'une révision Arch, sous la forme\n");
		fprintf(stderr, "                       <grange>/<module>--<branche>--<version>--<révision>\n");
		fprintf(stderr, "  <fin de révision>:   un certain nombre d'éléments de la précédente, qui\n");
		fprintf(stderr, "                       viendront remplacer.\n");
		exit(1);
	}
	
	decoupe1 = decouper(argv[1]);
	decoupe2 = decouper(argv[2]);
	
	/* Là on peut se planter grave si les paramètres ne respectent pas le format
	 * demandé. */
	
	if(!decoupe2[1]) /* Si les paramètres nous demandent de compléter en restant dans la même archive. */
	{
		afficherDecoupe(decoupe1[0], -1);
		fprintf(stdout, "/");
		for(n2 = 0; decoupe2[0][n2]; ++n2) {}
		for(n1 = 0; decoupe1[1][n1]; ++n1) {}
		if(n1 > n2) { afficherDecoupe(decoupe1[1], n1 - n2); fprintf(stdout, "--"); }
		afficherDecoupe(decoupe2[0], -1);
	}
	else
	{
		afficherDecoupe(decoupe2[0], -1);
		fprintf(stdout, "/");
		afficherDecoupe(decoupe2[1], -1);
	}
	free(decoupe2);
	free(decoupe1);
	fprintf(stdout, "\n");
	
	return 0;
}
