/*
 * Copyright (c) 2002-2003 Guillaume Outters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

%x FAIRE
DEBUT_LIGNE ^([\t \/])*

%{

/*----------------------------------------------------------------------------*/
/* BOGUE: Le code ne doit pas être collé en début de ligne
 * sous peine d'être ignoré. */

#include <sys/stat.h>
#include <sys/syslimits.h>
#include <errno.h>

#include "/Users/gui/src/c/UnixTools/automkdir.c"

#define MAX_INDENTATION 63
#define LARGEUR_TAB 4

struct uneConversion
{
	char * macro;
	int action; /* bits 0 et 1: lorsque la macro n'est pas définie, 2 et 3 lorsqu'elle l'est. Dans ces paquets, le bit de poids faible demande la mise en commentaire, le poids fort de décommenter. */
};

struct uneConversion g_conv;
char g_prefixe[MAX_INDENTATION+1]; /* Indentation des directives de préprocesseur; le code mis en commentaire est aligné sur cette indentation. */
int g_2nCommPrefixe; /* Deux fois le nombre de commentaires du préfixe */
int g_largeurPrefixe; /* Largeur du préfixe, en nombre d'espaces (la tabulation compte pour LARGEUR_TAB) */
int g_niveau;
int g_commenter;
int g_definie;

void faire()
{
	char * ptr;
	int l;
	int n;
	/*printf("%d", g_commenter);*/
	if(g_commenter & 1)
	{
		fprintf(stderr, "Je commente\n");
		fwrite(g_prefixe, 1, strlen(g_prefixe), yyout);
		/* On vire d'yytext tous les espaces situés avant notre préfixe,
		 * en faisant attention à conserver le même nombre de
		 * commentaires */
		for(l = g_largeurPrefixe - 2, n = g_2nCommPrefixe - 2, ptr = yytext; *ptr && l > 0; ++ptr)
		{
			l -= (*ptr == '\t' ? LARGEUR_TAB : 1);
			if(*ptr == '/' && --n < 0) break;
		}
		if(*ptr)
			fwrite(ptr, 1, strlen(ptr), yyout);
	}
	else if(g_commenter & 2)
	{
		/* On doit à tout prix virer deux slash. On essaie de virer ceux
		 * qui sont alignés avec les deux derniers de notre préfixe */
		
		fwrite(g_prefixe, 1, strlen(g_prefixe) - 2, yyout);
		for(l = g_largeurPrefixe - 2, ptr = yytext; *ptr && l > 0; ++ptr)
			l -= (*ptr == '\t' ? LARGEUR_TAB : 1);
		/* On cherche les deux prochains */
		for(n = 2; *ptr && n > 0; ++ptr)
			if(*ptr == '/')
				--n;
		if(*ptr)
			fwrite(ptr, 1, strlen(ptr), yyout);
	}
}

void faire2()
{
	char * ptr;
	char c;
	for(ptr = yytext; *ptr == '\t' || *ptr == ' ' || *ptr == '/'; ++ptr) {}
	c = *ptr;
	*ptr = 0;
	faire();
	*ptr = c;
	fwrite(ptr, 1, strlen(ptr), yyout);
}

void commencer(int definie)
{
	//printf("%%%%%% %d %%%%%%", definie);
	g_definie = definie;
	g_commenter = ((g_conv.action >> (definie ? 2 : 0)) & 0x03); /* A-t-on quelquechose à faire dans ce cas? */
	g_niveau = 1;
	BEGIN(FAIRE);
	return;
}

%}

%%

{DEBUT_LIGNE}#ifn?def\ ([A-Z_])+ {
	char * ptr;
	int def;

	fwrite(yytext, 1, strlen(yytext), yyout);
	for(ptr = yytext; *ptr != '#'; ++ptr) {}
	if(strcmp(&ptr[(def = (ptr[3] != 'n')) ? 7 : 8], g_conv.macro) == 0)
	{
		if(ptr > yytext + MAX_INDENTATION) ptr = yytext + MAX_INDENTATION;
		strncpy(g_prefixe, yytext, ptr - yytext); g_prefixe[ptr - yytext] = 0;
		for(ptr = g_prefixe, g_largeurPrefixe = 0, g_2nCommPrefixe; *ptr; ++ptr)
		{
			g_largeurPrefixe += (*ptr == '\t' ? LARGEUR_TAB : 1);
			if(*ptr == '/') ++g_2nCommPrefixe;
		}
		
		commencer(def);
	}
}

<FAIRE>{DEBUT_LIGNE}#ifn?def\ ([A-Z_])+ {
	faire2();
	++g_niveau;
}

<FAIRE>{DEBUT_LIGNE}#else {
	//printf("((( %d )))", g_niveau);
	if(g_niveau == 1)
	{
		fwrite(yytext, 1, strlen(yytext), yyout);
		commencer(!g_definie);
	}
	else if(g_niveau > 1)
		faire2();
}

<FAIRE>{DEBUT_LIGNE}#endif {
	if(--g_niveau == 0)
	{
		fwrite(yytext, 1, strlen(yytext), yyout);
		BEGIN(0);
	}
	else
		faire2();
}

<FAIRE>{DEBUT_LIGNE} { faire(); }

%%

int yywrap(void)
{
	return(1);
}

int main(int argc, char ** argv)
{
	char * ptr;
	int out, in;
	struct stat infos1, infos2;
	struct timeval temps[2];
	char cheminDest[PATH_MAX+1];
	int tailleCheminDest;
	char c;
	
	if(argc < 2)
	{
		fprintf(stderr, "### %s - simili-préprocesseur Java\n", argv[0]);
		fprintf(stderr, "### Utilisation: %s <conv> [-d <dest>] <fichiers>\n", argv[0]);
		fprintf(stderr, "###     <conv>     conversion à appliquer, de la forme [(+|-)][!]<MACRO>\n");
		fprintf(stderr, "###                active/désactive les #ifdef (ou #ifndef) <MACRO>\n");
		fprintf(stderr, "###                sans le signe, l'action porte sur la macro et son inverse.\n");
		fprintf(stderr, "###                Ainsi \"!CHOSE\" donnera le même résultat que deux appels\n");
		fprintf(stderr, "###                consécutifs \"-CHOSE\" et \"+!CHOSE\"\n");
		fprintf(stderr, "###     <dest>     répertoire destination des fichiers traités\n");
		fprintf(stderr, "###     <fichiers> fichiers à traiter\n");
		goto e0;
	}
	
	/* Interprétation de la conversion */
	
	if(argv[1][0] == '-' || argv[1][0] == '+')
	{
		g_conv.action = (argv[1][0] == '+' ? 0x2 : 0x1) << (argv[1][1] == '!' ? 0x0 : 0x2);
		g_conv.macro = &argv[1][argv[1][1] == '!' ? 2 : 1];
	}
	else
	{
		g_conv.action = (argv[1][0] == '!' ? 0x6 : 0x9);
		g_conv.macro = &argv[1][argv[1][0] == '!' ? 1 : 0];
	}
	for(ptr = g_conv.macro; *ptr; ++ptr)
		if((*ptr < 'A' || *ptr > 'Z') && *ptr != '_')
		{
			fprintf(stderr, "### La macro doit être composée uniquement des caractères A à Z et _\n");
			goto e0;
		}
	if(ptr == g_conv.macro)
	{
		fprintf(stderr, "### La macro ne peut être vide\n");
			goto e0;
	}
	
	/* Travail */
	
	argc -= 2;
	argv += 2;
	if(argc > 0 && strcmp(*argv, "-d") == 0)
	{
		if((tailleCheminDest = strlen(argv[1]) + 1) > PATH_MAX)
		{
			fprintf(stderr, "### Le nom de la destination est trop long: %s\n", argv[1]);
			goto e0;
		}
		strcpy(cheminDest, argv[1]);
		cheminDest[tailleCheminDest-1] = '/';
		cheminDest[tailleCheminDest] = 0;
		
		argc -= 2;
		argv += 2;
		
		if(stat(cheminDest, &infos1) < 0)
		{
			fprintf(stderr, "### Impossible de se renseigner sur la destination %s: %s\n", cheminDest, strerror(errno));
			goto e0;
		}
		
		if(stat(".", &infos2) < 0)
		{
			fprintf(stderr, "### Répertoire courant illisible: %s\n", strerror(errno));
			goto e0;
		}
		
		if(infos1.st_dev == infos2.st_dev && infos1.st_ino == infos2.st_ino)
		{
			fprintf(stderr, "### La source (répertoire courant) et la destination sont les mêmes. %s ne sait pas remplacer sur place.\n", argv[-4]);
			goto e0;
		}
	}
	else
	{
		yyout = stdout;
		tailleCheminDest = 0;
	}
	if(argc <= 0)
	{
		yylex();
	}
	else for(; argc > 0; ++argv, --argc)
	{
		g_commenter = 0;
		
		if(stat(*argv, &infos1) < 0 || (yyin = fopen(*argv, "r")) == NULL)
		{
			fprintf(stderr, "### Impossible d'ouvrir %s\n", *argv);
			goto e0;
		}
		if(tailleCheminDest)
		{
			if(tailleCheminDest + strlen(*argv) > PATH_MAX)
			{
				fprintf(stderr, "### Nom trop long: %s%s\n", cheminDest, *argv);
				goto e0;
			}
			strcpy(&cheminDest[tailleCheminDest], *argv);
			for(ptr = &cheminDest[tailleCheminDest+strlen(*argv) - 1]; ptr >= &cheminDest[0] && *ptr != '/'; --ptr) {}
			c = *(++ptr);
			*ptr = 0;
			if(creerDossier(cheminDest, 0777) < 0)
			{
				fprintf(stderr, "### Impossible de créer le dossier %s: %s\n", cheminDest, strerror(errno));
				goto e0;
			}
			*ptr = c;
			if(!(yyout = fopen(cheminDest, "w")))
			{
				fprintf(stderr, "### Impossible d'ouvrir en écriture %s (%s)\n", cheminDest, strerror(errno));
				goto e1;
			}
		}
		
		yylex();
		
		if(tailleCheminDest)
		{
			fflush(yyout);
			temps[0].tv_sec = infos1.st_atimespec.tv_sec;
			temps[0].tv_usec = infos1.st_atimespec.tv_nsec / 1000;
			temps[1].tv_sec = infos1.st_mtimespec.tv_sec;
			temps[1].tv_usec = infos1.st_mtimespec.tv_nsec / 1000;
			futimes(yyout->_file, &temps[0]);
			fclose(yyout);
		}
		fclose(yyin);
	}
	
	return(0);
	
/*e2:	fclose(yyout);*/
e1:	fclose(yyin);
e0:	return(1);
}
