/*
 * Copyright (c) 2005 Guillaume Outters
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

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#define SYSLOG_NAMES
#include <syslog.h>
#include <stdarg.h>
#include <sys/errno.h>
#include <fcntl.h>

int g_dest;
int g_syslog;

char * nomDe(char ** argv)
{
	char * r;
	if((r = strrchr(argv[0], '/'))) return(++r); else return(argv[0]);
}

#define COLONNES 80
void auSecours(char ** argv)
{
	char * nom;
	CODE * code;
	int pos;
	nom = nomDe(argv);
	fprintf(stderr, "# %s\n", nom);
	fprintf(stderr, "# Trace multiplexée\n");
	fprintf(stderr, "# © 2005 Guillaume Outters\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Utilisation: %s [<fichier>] [-s|-S <catégorie>] <commande> [<param>*]\n", nom);
	fprintf(stderr, "  -s                            passe par syslog (catégorie user)\n");
	fprintf(stderr, "  -S <catégorie>                passe par une catégorie syslog précisée:");
	pos = COLONNES;
	for(code = &facilitynames[0]; code->c_name; ++code)
	{
		if(pos + 1 + strlen(code->c_name) + 1 > COLONNES)
		{
			fprintf(stderr, "\n                                ");
			pos = 32;
		}
		else
			fprintf(stderr, " ");
		fprintf(stderr, "%s%c", code->c_name, code[1].c_name ? ',' : '.');
		pos += 1 + strlen(code->c_name) + 1;
	}
	fprintf(stderr, "\n");
	fprintf(stderr, "  <fichier>                     fichier de traces. Les erreurs y sont\n");
	fprintf(stderr, "                                distinguées des traces en étant préfixées d'un\n");
	fprintf(stderr, "                                # .\n");
	fprintf(stderr, "De <fichier> et -s, au moins un doit être spécifié. L'ordrerelatif de ces deux arguments est important, puisque qu'un <fichier> placé après un -s sera interprété comme la commande à lancer.\n");
	fprintf(stderr, "%s enregistre les traces de <commande> tout en laissant ses flux entrants et sortants circuler selon leur bon vouloir.\n", nom);
	exit(1);
}

/* Trace et sort un bloc mémoire. La trace s'arrête sur caractère nul. Si le
 * paramètre 'taille' est inférieur ou égal à 0, la chaîne sortie aussi;
 * sinon un caractère nul est inséré (puis retiré) en message[taille] pour que
 * la trace trouve où s'arrêter. Attention donc à réserver un octet de plus au
 * cas où. */
/* ATTENTION: bien lire la description ci-dessus, sous peine d'un débordement de
 * de mémoire. */
void tracer(int type, char * message, int taille)
{
	char c;
	if(taille <= 0)
	{
		taille = strlen(message);
		c = 0;
	}
	else
	{
		c = message[taille];
		message[taille] = 0;
	}
	write(type + 1, message, taille);
	if(g_syslog != -1)
		syslog(type ? LOG_ERR : LOG_INFO, message);
	if(g_dest >= 0)
	{
		if(type) write(g_dest, "# ", 2);
		write(g_dest, message, taille);
	}
	if(c) message[taille] = c;
}

void tracerf(int type, char * format, ...)
{
	va_list args;
	char * con;
	va_start(args, format);
	vasprintf(&con, format, args);
	if(con)
	{
		tracer(type, con, -1);
		free(con);
	}
	else /* On trace nos paramètres un par un, c'est mieux que rien. */
	{
		tracer(type, format, -1);
		/* À FAIRE: parcourir le format et pour chaque %…x reconnu, afficher le
		 * paramètre correspondant en faisant gaffe à ne pas avoir à allouer de
		 * mémoire (par exemple pour un %d, le transformer en %.8d et avoir
		 * alloué sur la pile la place nécessaire en début de procédure). */
	}
	va_end(args);
}

/* Interprète les paramètres de configuration, et renvoie le numéro du premier
 * paramètre non interprété (début de la ligne de commande à lancer). Ou bien
 * fait quitter le programme si les paramètres ne lui conviennent pas. */
int lireParametres(char ** argv)
{
	char ** debut = argv;
	
	g_dest = -2;
	g_syslog = -1;
	
	while(*++argv)
	{
		if(strcmp(*argv, "-h") == 0 || strcmp(*argv, "--help") == 0)
			break; /* On retombe dans le cas « pas trouvé ce qu'il fallait » donc aide. */
		else if(strcmp(*argv, "-s") == 0 || strcmp(*argv, "-S") == 0)
		{
			if(g_syslog != -1) auSecours(debut);
			if(g_dest == -2) /* Si l'on arrive avant qu'un fichier ait été donné, il n'y aura pas de fichier, un point c'est tout. */
				g_dest = -1;
			if((*argv)[1] == 'S')
			{
				if(*++argv == NULL) auSecours(debut);
				CODE * code;
				for(code = facilitynames; code->c_name; ++code)
					if(strcmp(code->c_name, *argv) == 0)
						break;
				if(!code->c_name) auSecours(debut);
				g_syslog = code->c_val;
			}
			else
				g_syslog = LOG_USER;
		}
		else if(g_dest == -2)
		{
			if((g_dest = open(*argv, O_RDWR | O_CREAT, 0700)) < 0)
				tracerf(1, "impossible d'ouvrir le fichier de log %s", *argv);
			ftruncate(g_dest, 0);
		}
		else
		{
			if(g_syslog != -1)
				openlog(nomDe(debut), 0, g_syslog);
			return argv - debut;
		}
	}
	auSecours(debut); /* On n'est pas passé par notre else, donc il manque au moins un argument donnant la commande à lancer et filtrer. */
}

#define TAILLE_MAX 1048576
void tourner(int s, int e)
{
	fd_set voulus;
	fd_set eus;
	int f[2];
	char mem[2][TAILLE_MAX + 2]; /* Le +2 pour pouvoir y ajouter, si nécessaire, un retour à la ligne et un caractère nul. */
	int pos[2];
	int debut, p, fin;
	int z, y;
	int n;
	
	f[0] = s;
	f[1] = e;
	
	FD_ZERO(&voulus);
	for(z = 2; --z >= 0;)
	{
		pos[z] = 0;
		FD_SET(f[z], &voulus);
	}
	
	while(1)
	{
		FD_COPY(&voulus, &eus);
		switch(select(FD_SETSIZE, &eus, NULL, NULL, NULL))
		{
			case 0:
				break;
			case -1:
				/* À FAIRE. */
				break;
			default:
				for(z = 2; --z >= 0;)
					if(FD_ISSET(f[z], &eus)) /* Chouette, de la lecture! */
					{
						switch(n = read(f[z], &mem[z][pos[z]], TAILLE_MAX - pos[z]))
						{
							case 0: /* Eh ben on en est arrivé à bout, finalement… */
							case -1: /* Le résultat est le même, bien que la méthode pour y arriver soit moins orthodoxe. */
								if(pos[z]) /* Si, avant de recevoir la fermeture, on a obtenu des données sans retour à la ligne en queue, on les affiche. */
									tracer(z, &mem[z][0], pos[z]);
								FD_CLR(f[z], &voulus);
								for(y = 2; --y >= 0;)
									if(FD_ISSET(f[y], &voulus))
										break;
								if(y < 0)
									goto fini;
								break;
							default: /* Des données! */
								fin = (p = pos[z]) + n;
								for(debut = 0; p < fin; ++p)
								{
									if(mem[z][p] == '\n')
									{
										tracer(z, &mem[z][debut], p + 1 - debut);
										debut = p + 1;
									}
								}
								if(debut > 0 && debut < p) /* S'il nous reste un début de ligne, on se le recale en début de mémoire pour compléter la prochaine fois. */
									memmove(&mem[z][0], &mem[z][debut], p - debut);
								else if(debut == 0 && fin == TAILLE_MAX) /* Si on a déniché la perle rare en une ligne contenant TAILLE_MAX caractères sans retour à la ligne, on l'affiche avant d'entrer en dépassement de mémoire. */
									tracer(z, &mem[z][0], debut = p);
								pos[z] = p - debut;
								break;
						}
					}
				break;
			
		}
	}
fini:
	exit(0);
}

int main(int argc, char ** argv)
{
	int fils;
	int err;
	int tube[2][2]; /* Un couple pour stdout, un pour stderr; et dans chaque couple, un pour que le processus lancé les envoie, et un pour que nous les recevions. */
	int z;
	
	argc = lireParametres(argv);
	
	for(z = 2; --z >= 0;)
		if(pipe(&tube[z][0]) != 0)
		{
			tracerf(1, "impossible d'entuber: %s\n", strerror(errno));
			exit(1);
		}
	switch(fils = fork())
	{
		case 0: /* Petit nouveau. */
			for(z = 2; --z >= 0;)
			{
				close(tube[z][0]);
				close(z + 1);
				dup(tube[z][1]);
			}
			break;
		case -1: /* Oups! */
			err = errno;
			tracerf(1, "impossible de nous cloner: %s\n", strerror(err));
			exit(1);
		default:
			close(0);
			for(z = 2; --z >= 0;)
				close(tube[z][1]);
			tourner(tube[0][0], tube[1][0]);
			exit(1);
	}
	
	/* Heureux papa, ou cloneur raté! */
	/* Dans les deux cas, on essaie de lancer le fiston dans la vie. */
	
	execvp(argv[argc], &argv[argc]);
	fprintf(stderr, "impossible de lancer %s: %s\n", argv[argc], strerror(errno)); /* À FAIRE: afficher si possible les paramètres en même temps qu'argv[0]. */
	fflush(stderr);
	exit(1);
}
