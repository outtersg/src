#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <Std/Tableaux.h>

#define TAILLE 4096

void utilisation(char * nomCommande)
{
	fprintf(stderr, "#  Garg\n");
	fprintf(stderr, "#  Itération sur une commande de plusieurs valeurs d'un argument\n");
	fprintf(stderr, "#  © Guillaume Outters 2003\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Utilisation: %s <commande> (<arg>)* {} (<arg>)*\n", nomCommande);
	fprintf(stderr, "\n");
	fprintf(stderr, "Pour chaque ligne de l'entrée standard, exécute <commande> avec pour\n");
	fprintf(stderr, "arguments la suite (<arg>)* {} (<arg>)*, où {} est remplacé par la ligne en\n");
	fprintf(stderr, "entrée.\n");
	fprintf(stderr, "Si la dernière ligne est un caractère retour, aucun argument n'est généré.\n");
	fprintf(stderr, "Pour forcer un dernier argument vide, envoyez deux lignes vides.\n");
	
	exit(1);
}

int faisPeter(char ** mesArguments, char ** ilEtaitUnPetitNavire, int mousse, unTableau<char> & remplacant, int ligne, int dejaFoire)
{
	char ** copieur;
	int r;
	
	if(dejaFoire) goto foire;
	
	/* On recopie les arguments */
	
	for(copieur = ilEtaitUnPetitNavire - 1; *mesArguments;)
		*++copieur = *++mesArguments;
	
	/* Et hop, un phagocytage! */
	
	if(!remplacant.ajouter((char)0)) goto foire;
	ilEtaitUnPetitNavire[mousse] = remplacant.detacher();
	
	/* Reste plus qu'à faire tourner */
	
	switch(r = vfork())
	{
		case -1:
			return -1;
		case 0:
			exit(execvp(ilEtaitUnPetitNavire[0], ilEtaitUnPetitNavire));
		default:
			waitpid(r, &r, 0);
			if(WIFEXITED(r) && WEXITSTATUS(r))
			{
				fprintf(stderr, "### Avec %s: %s\n", ilEtaitUnPetitNavire[mousse], strerror(WEXITSTATUS(r)));
				r = (WEXITSTATUS(r) == E2BIG) ? 0 : -1; // C'est excusable, ou plutôt encore de la faute de l'utilisateur
			}
			break;
	}
	
	return r;
	
foire:	fprintf(stderr, "### ligne %d vraiment trop trop longue\n", ligne);
		return(0); // Erreur minime, on ne sort pas pour si peu mais l'utilisateur devrait mettre un peu plus de retours à la ligne dans les romans qu'il nous envoie.
}

int main(int argc, char ** argv)
{
	int insertion;
	char accu[TAILLE];
	unTableau<char> cumul;
	char * ptr, * debut, * fin;
	char ** args;
	int foire = 0; // Si en cours de recopie d'une ligne vraiment, vraiment longue on manque de place, inutile de continuer
	int ligne;
	
	for(insertion = argc; --insertion >= 2;)
		if(strcmp(argv[insertion], "{}") == 0)
			break;
	if(--insertion < 1) // On n'a pas trouvé notre point d'insertion, c'est de la faute de l'utilisateur
		utilisation(argv[0]);
	
	/* L'invocation du bazar se fera sur une copie de travail, au cas où l'une
	 * d'elle déciderait de tout casser pour embêter les suivantes */
	
	if(!(args = (char **)malloc(argc * sizeof(char *)))) // Nos arguments -1 pour le nôtre + 1 pour le null
	{
		errno = ENOMEM;
		perror("Initialisation échouée");
		exit(1);
	}
	
	/* Tant qu'on peut lire, on lit */
	
	ligne = 1;
	while((fin = (char *)read(0, accu, TAILLE)) > 0)
	{
		fin = &accu[0] + (int)fin;
		
		/* Maintenant que c'est lu, autant exploiter */
		
		for(ptr = debut = accu; ptr < fin; ++ptr)
			if(*ptr == '\n') // Oh, notre séparateur!
			{
				if(!foire && !cumul.ajouter(debut, ptr - debut)) foire = 1;
				if(faisPeter(argv, args, insertion, cumul, ligne, foire))
					goto boum;
				
				++ligne;
				debut = ptr + 1;
				foire = 0;
			}
		
		/* Bon, on n'a pas trouvé, qu'à cela ne tienne, on engrange quand même */
		
		if(ptr == fin)
			if(!foire && !cumul.ajouter(debut, ptr - debut)) foire = 1;
	}
	
	if(cumul.taille() > 0 && faisPeter(argv, args, insertion, cumul, ligne, foire))
boum:	return(1);
	
	return(0);
}
