// http://rachid.koucha.free.fr/tech_corner/pty_pdip_fr.html
// Permet d'enrober un psql (ou un pg_dump, en lur balançant < /dev/null pour qu'il n'attende pas éternellement une entrée) pour que la saisie de mot de passe se fasse automatiquement depuis le programme, plutôt que de requérir une saisie dans le terminal.
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#define __USE_BSD
#include <termios.h>
#include <sys/select.h>
#include <sys/ioctl.h>
#include <string.h>

#define TRACE if(0) fprintf

enum
{
	S_MELEE,
};

enum
{
	I_PTY = -2,
	I_STDIN = -3
};

static struct termios g_infosStdin;
static int g_fermeEnFin = 1;
static int g_pipelette = 1; /* Restitue-t-on sur le TTY maître le contenu de nos échanges scénarisés? */

typedef struct Sortie Sortie;

typedef struct Etape Etape;
struct Etape
{
	const char * attente;
	int pauseMilli;
	const char * saisie;
	Etape * suite;
	int vus; /* Nombre d'octets de l'attente déjà vus passer. */
	int injecteur;
	Sortie * echo;
	char gobeEchanges;
};

typedef struct Insert Insert;
struct Insert
{
	char * pos; /* Dans le bloc de sa sortie. */
	char * insert;
	int taille;
	int dejaEcrits;
};

#define NSORTIES 2
#define TBLOC 0x1000

struct Sortie
{
	char bloc[TBLOC];
	int reste;
	char * pBloc;
	int sortie;
	
	Insert * inserts;
	int nInserts;
	int nInsertsAlloues;
	
	char * descr;
};
Insert * Sortie_insert(Sortie * this, char * insert, int taille);
void Sortie_memmove(Sortie * this, char * dest, char * source, int n);

typedef struct Maitre Maitre;
struct Maitre
{
	Sortie sorties[NSORTIES];
};

void Maitre_ecrire(Maitre * this, int numBloc);

inline static void echo(int sortie, const char * octets, int n)
{
	if(g_pipelette && n && sortie >= 0)
		write(sortie, octets, n);
}

int attends(int f, const char * attente, Sortie * echo)
{
	int t2;
	char bloc[0x1000];
	int t = 0;
	while(1)
	{
		switch(t2 = read(f, &bloc[t], 1)) // Pour le moment octet par octet: on ne veut pas en lire trop; on optimisera plus tard.
		{
			case 0:
			case -1:
				return -1;
		}
		
		if(echo)
			Sortie_insert(echo, &bloc[t], t2);

		t += t2;
		bloc[t] = 0;

		if(strstr(bloc, attente))
		{
			TRACE(stderr, "trouve\n");
			return 0;
		}
	}
}

/**
 * @return Si les octets closent l'attente: pointeur sur ce qu'on laisse en non consommé; sinon NULL si la chaîne a été absorbée mais que l'on reste en attente de cette étape.
 */
char * injecteEnEtape(Etape * etape, Sortie * travail, int n)
{
	int voulus = strlen(etape->attente);
	int reste = n;
	int nVus;
	int pregobes = etape->vus;
	char * octets = &travail->pBloc[travail->reste - n];
	char * depart = octets;
	char * premierGobe = octets;
	
	while(etape->vus < voulus)
	{
		/* On veut avancer dans la chaîne attendue à cette étape. */
		
		/* Déjà, a-t-on un octet à lire dans notre source? */
		
		if(--reste < 0)
		{
			/* Si l'on reste coincés au beau milieu d'une étape, on ne sait pas encore si ce qu'on a déjà lu sera finalement consommé par nous, ou libéré (parce que la fin ne correspond pas). Dans ce cas, on fait de la rétention pour le moment, en tronquant avant ce qui nous appartient. */
			Sortie_memmove(travail, premierGobe, octets, 0);
			return NULL;
		}
		
		/* Bon, essayons de le faire correspondre au prochain octet attendu. */
		/* Attention, à la moindre non-concordance, si nous avions déjà considéré comme passés des octets (car ils correspondaient à notre début), il nous faudra les restituer (en nous excusant platement d'avoir fait de la rétention). */
		
		retente:
		if(*octets != etape->attente[nVus = etape->vus])
		{
			/* Si l'octet n'est pas le prochain attendu, on ne remet pas nécessairement notre état à 0; ainsi, si on attend abcabd, et qu'on reçoit abcabcabd, le second c arrivera alors que l'on aura déjà "vu" 5 caractères (abcab), mais le c ne correspondant pas au d alors attendu, on échoue à poursuivre plus loin, cependant on ne remet pas le compteur à 0, mais à 2, car le dernier ab passé (qui correspondait à attente[3..4]) correspond aussi à attente[0..1]. */
			/* On recherche donc le plus grand dernier segment déjà vu qui puisse être un segment de début. */
			while(--etape->vus >= 0)
			{
				if(!memcmp(etape->attente, &etape->attente[etape->vus], etape->vus))
				{
					/* Restitution de ce qu'on avait mangé par erreur. */
					premierGobe += nVus - etape->vus; /* Ce qu'on avait gobé dans le bloc mémoire actuellement analysé peut être restitué "logiquement". */
					if(pregobes && etape->gobeEchanges)
					{
						pregobes -= nVus - etape->vus;
						Sortie_insert(travail, (char *)etape->attente, nVus - etape->vus); /* Mais si on l'avait gobé sur la précédente injection, il nous faut aller fouiller notre mémoire pour retrouver quoi restituer. Coup de chance, pour une étape "simple" (sans regex), ce qu'on a gobé est à l'octet près notre crible de gobage. */
					}
					goto retente;
				}
			}
			/* Bon, si on était déjà acculé, et qu'on n'a pas trouvé, on ne trouvera pas plus en arrière. On sort, en laissant notre valeur à -1 pour qu'elle repasse à 0 juste après. */
			++premierGobe;
		}
		++etape->vus;
		
		/* Celui-ci est passé (avec ou sans avancée, on s'en fiche). */
		
		++octets;
	}
	
	/* En ayant passé l'étape, nous avons troué ce qu'il nous a été fourni en entrée. Comblons le trou en recollant ce qui suit le trou à ce qui le précède. */
	
	if(etape->gobeEchanges)
	{
		Sortie_memmove(travail, premierGobe, octets, reste);
		octets = premierGobe;
	}
	
	return octets;
}

void etapeControle(Etape * etape)
{
}

Etape * pousseAuTube(Etape * etape, int posRelative)
{
	TRACE(stderr, "repéré sur le tube: %s\n", etape->attente);
	usleep(etape->pauseMilli * 1000);
	if(etape->echo && !etape->gobeEchanges)
	{
		etape->echo->reste += posRelative;
		Sortie_insert(etape->echo, (char *)etape->saisie, strlen(etape->saisie));
		Sortie_insert(etape->echo, "\n", 1);
		etape->echo->reste -= posRelative;
	}
	write(etape->injecteur, etape->saisie, strlen(etape->saisie));
	write(etape->injecteur, "\n", 1);
	return etape->suite;
}

Etape * injecteEnEtapes(Etape * etape, Sortie * travail, int n)
{
	char * ptrReste;
	
	while(etape)
	{
		/* Traitement des étapes de contrôle. */
		
		if(!etape->attente)
		{
			TRACE(stderr, "ETAPE %d\n", (int)etape->saisie);
			etapeControle(etape);
			etape = etape->suite;
			continue;
		}
		
		TRACE(stderr, "ETAPE %s\n", etape->attente);
		if(!(ptrReste = injecteEnEtape(etape, travail, n)))
			return etape;
		
		n = &travail->pBloc[travail->reste] - ptrReste;
		
		etape = pousseAuTube(etape, -n);
	}
	
	return etape;
}

#define O_SURVEILLER 0x2

void Sortie_init(Sortie * this, int fd, char * descr)
{
	this->sortie = fd;
	this->reste = 0;
	this->pBloc = &this->bloc[0];
	
	this->inserts = NULL;
	this->nInsertsAlloues = 0;
	this->nInserts = 0;
	
	this->descr = descr;
}

Insert * Sortie_insert(Sortie * this, char * insert, int taille)
{
	Insert * nouveau;
	
	if(this->nInserts >= this->nInsertsAlloues)
	{
		Insert * anciens = this->inserts;
		this->inserts = (Insert *)malloc((++this->nInsertsAlloues) * sizeof(Insert));
		if(anciens)
		{
			memcpy(this->inserts, anciens, this->nInserts * sizeof(Insert));
			free(this->inserts);
		}
	}
	
	nouveau = & this->inserts[this->nInserts];
	nouveau->pos = &this->pBloc[this->reste];
	nouveau->insert = insert;
	nouveau->taille = taille;
	nouveau->dejaEcrits = 0;
	
	++this->nInserts;
	return nouveau;
}

void Sortie_recaler(Sortie * this, char * dest, char * source)
{
	int n;
	for(n = this->nInserts; --n >= 0;)
		if(this->inserts[n].pos > source)
			this->inserts[n].pos -= source - dest;
		else if(this->inserts[n].pos > dest)
			this->inserts[n].pos = dest;
}

void Sortie_memmove(Sortie * this, char * dest, char * source, int n)
{
	if(source > dest)
	{
		if(n > 0)
			memmove(dest, source, n);
		this->reste -= source - dest; /* On part du principe que ce qui est supprimé était dans le reste à écrire. */
		Sortie_recaler(this, dest, source);
	}
}

void Sortie_ecrireInsert(Sortie * this)
{
	int n;
	Insert * pInsert = &this->inserts[0];
	if((n = write(this->sortie, &pInsert->insert[pInsert->dejaEcrits], pInsert->taille - pInsert->dejaEcrits)) >= 0)
		if((pInsert->dejaEcrits += n) >= pInsert->taille)
			if(--this->nInserts > 0)
				memmove(&this->inserts[0], &this->inserts[1], this->nInserts * sizeof(Insert));
}

int Sortie_ecrire(Sortie * this)
{
	int rc = this->reste;
	
	if(this->nInserts)
	{
		if(this->pBloc == this->inserts[0].pos)
		{
			Sortie_ecrireInsert(this);
			return 0;
		}
		else if(rc > this->inserts[0].pos - this->pBloc)
			rc = this->inserts[0].pos - this->pBloc;
	}
	
	if((rc = write(this->sortie, this->pBloc, rc)) > 0)
	{
		if((this->reste -= rc) <= 0)
		{
			Sortie_recaler(this, &this->bloc[0], &this->pBloc[rc]);
			this->pBloc = &this->bloc[0];
		}
		else
			this->pBloc += rc;
		TRACE(stderr, "   Transmis %s: %d\n", this->sortie == 1 || this->sortie == 2 ? "↑" : "↓", rc);
	}
	else
	{
		close(this->sortie);
		this->sortie = -1;
	}
	
	return rc;
}

static inline void preparerSelectEntrant(int f, int placeRestante, fd_set * descrs, int * fmax, char * descr)
{
	if(f >= 0 && placeRestante < TBLOC)
	{
		FD_SET(f, descrs);
		if(*fmax < f)
			*fmax = f;
		TRACE(stderr, "attends jusqu'à %d octets sur %s\n", placeRestante, descr);
	}
}

static inline void Sortie_preparerSelect(Sortie * this, fd_set * descrs, int * fmax)
{
	if(this->reste)
	{
		FD_SET(this->sortie, descrs);
		if(*fmax < this->sortie)
			*fmax = this->sortie;
		TRACE(stderr, "attends place pour écrire %d octets sur %s\n", this->reste, this->descr);
	}
}

static inline int Sortie_ecrireSi(Sortie * this, fd_set * descrs)
{
	int rc;
	
	if(this->sortie >= 0 && FD_ISSET(this->sortie, descrs))
		return Sortie_ecrire(this);
	
	return 0;
}

Etape * lire(fd_set * descrs, int * descr, Sortie * dest, int opt, Etape * etapeCourante)
{
	int rc;
	
	if(*descr < 0)
	{
		TRACE(stderr, "-> Fermeture du %d (%s)\n", dest->sortie, dest->descr);
		close(dest->sortie);
		dest->sortie = -1;
	}
	if(*descr >= 0 && FD_ISSET(*descr, descrs))
	{
		if((rc = read(*descr, &dest->pBloc[dest->reste], TBLOC - (dest->pBloc - &dest->bloc[0]) - dest->reste)) < 0)
		{
			fprintf(stderr, "Erreur %d sur read entree standard\n", errno);
			return etapeCourante;
		}
		
		if(rc > 0)
		{
			dest->reste += rc;
			if(opt & O_SURVEILLER)
				etapeCourante = injecteEnEtapes(etapeCourante, dest, rc);
				return etapeCourante;
			/* else on est dans le cas fermeture de stdin, ci-dessous. */
		}
		
		TRACE(stderr, "-> Fermeture du %d\n", *descr);
		close(*descr);
		*descr = -1;
	}
	
	return etapeCourante;
}

void Sortie_fermer(Sortie * this)
{
	if(this->sortie >= 0)
	{
		if(isatty(this->sortie))
			write(this->sortie, "\n\x04", 2);
		else
			close(this->sortie);
		this->sortie = -1;
	}
}

void maitre(int fdm, int tube, Etape * etape)
{
	int e = 0;
	
	TRACE(stderr, "%d: stdin maître\n", e);
	TRACE(stderr, "%d: stdin appli\n", tube);
	TRACE(stderr, "%d: pty appli\n", fdm);

	Maitre maitre;
	Sortie_init(&maitre.sorties[0], tube, "stdin fils");
	Sortie_init(&maitre.sorties[1], 1, "stdout");
	
	Sortie * pseudoEcho = tube == fdm ? NULL : &maitre.sorties[1];
	
	/* Maintenant que l'on connaît les descripteurs de fichier réels, on peut brancher l'injecteur des étapes. */
	
	Etape * pEtape;
	for(pEtape = etape; pEtape; pEtape = pEtape->suite)
	{
		if(pEtape->attente)
		{
			pEtape->echo = pseudoEcho;
			pEtape->gobeEchanges = 0;
			switch((int)pEtape->injecteur)
			{
				case I_STDIN: pEtape->injecteur = tube; break;
				case I_PTY: pEtape->injecteur = fdm; break;
			}
		}
	}
	
	/* On passe les première étapes, avant ouverture du stdin maître vers le stdin appli. */
	
	while(etape && etape->attente)
	{
		attends(fdm, etape->attente, etape->gobeEchanges ? NULL : etape->echo);
		/* Les premières étapes sont généralement celles de demande de mot de passe: on les fournit au PTY plutôt qu'au stdin (s'ils sont différents l'un de l'autre). */
		etape = pousseAuTube(etape, 0);
	}
	
	int fmax;
int  rc;
  fd_set fd_in;
	fd_set etatsS;
    // Code du processus pere
	while (fdm >= 0)
    {
		fmax = -1;
		TRACE(stderr, "-> (Attente de mouvement)\n");
      // Attente de données de l'entrée standard et du PTY maître
      FD_ZERO(&fd_in);
		preparerSelectEntrant(e, maitre.sorties[0].reste, &fd_in, &fmax, "stdin");
		preparerSelectEntrant(fdm, maitre.sorties[1].reste, &fd_in, &fmax, "TTY fils");
		FD_ZERO(&etatsS);
		Sortie_preparerSelect(&maitre.sorties[0], &etatsS, &fmax);
		Sortie_preparerSelect(&maitre.sorties[1], &etatsS, &fmax);
		rc = select(fmax + 1, &fd_in, &etatsS, NULL, NULL);
      switch(rc)
      {
        case -1 : fprintf(stderr, "Erreur %d sur select()\n", errno);
                  exit(1);
        default :
        {
				Sortie_ecrireSi(&maitre.sorties[0], &etatsS);
				Sortie_ecrireSi(&maitre.sorties[1], &etatsS);
			// S'il y a des donnees sur l'entree standard
				etape = lire(&fd_in, &e, &maitre.sorties[0], 0, etape);
				if(fdm == tube) /* tube et fdm sont-ils liés? Si oui, tube devra suivre ld destin d'fdm. */
					tube = -2;
				etape = lire(&fd_in, &fdm, &maitre.sorties[1], O_SURVEILLER, etape);
				if(tube == -2)
					tube = fdm;
				
				/* Si plus d'étape dans le scénario, on considère le stdin terminé (sauf si l'appelant a demandé explicitement à maintenir ouvert à la fin). */
				if(!etape && g_fermeEnFin && isatty(0))
				{
					TRACE(stderr, "-> Fermeture du stdin maître (par fin du scénario)\n");
					e = -1;
				}
				if(e < 0 && tube >= 0 && !maitre.sorties[0].reste)
				{
					TRACE(stderr, "-> Fermeture du stdin appli (notre stdin étant fermé ou considéré comme tel)\n");
					Sortie_fermer(&maitre.sorties[0]);
					tube = -1;
				}
        }
      } // End switch
    } // End while
	TRACE(stderr, "-> (Fini)\n");
}

char * const * analyserParams(char * const argv[], Etape ** etapes)
{
	int iDefaut = I_PTY;
	
	while(*++argv)
	{
		if(strcmp(argv[0], "-e") == 0 && argv[1] && argv[2])
		{
			etapes[0] = (Etape *)malloc(sizeof(Etape));
			etapes[0]->attente = argv[1];
			etapes[0]->pauseMilli = 300;
			etapes[0]->saisie = argv[2];
			etapes[0]->suite = NULL;
			etapes[0]->vus = 0;
			etapes[0]->injecteur = iDefaut;
			etapes = & etapes[0]->suite;
			argv += 2;
		}
		else if(strcmp(argv[0], "-") == 0)
		{
			etapes[0] = (Etape *)malloc(sizeof(Etape));
			etapes[0]->attente = NULL;
			etapes[0]->saisie = (char *)S_MELEE;
			etapes[0]->suite = NULL;
			etapes = & etapes[0]->suite;
			/* Les étapes après celle-ci injecteront vers le stdin de l'appli, non plus vers son PTY comme initialement. */
			iDefaut = I_STDIN;
		}
		else if(strcmp(argv[0], ".") == 0)
			g_fermeEnFin = 0;
		/* else if(!nEtapes) alors le premier argument est un script à exécuter, façon sed */
		else
			break;
	}
	return argv;
}

int main(int argc, char * const argv[])
{
	int fdm, fds;
	int rc;
	int pos;
	Etape * premiereEtape;
	
	/* Analyse des paramètres. */
	
	premiereEtape = NULL;
	argv = analyserParams(argv, & premiereEtape);
	if(!premiereEtape || !*argv)
	{
		fprintf(stderr, "# Utilisation: sonpty (-e <chaîne attendue> <réponse>|-)+ <commande> <arg>*\n");
		fprintf(stderr, "   -\n");
		fprintf(stderr, "     ouverture des vannes. À partir de ce -, le stdin est reversé vers le fils\n");
		fprintf(stderr, "     en même temps que les réponses du scénario.\n");
		exit(1);
	}
	
	/* Lancement. */
	
	if((fdm = posix_openpt(O_RDWR)) < 0) { fprintf(stderr, "Erreur %d sur posix_openpt()\n", errno); return 1; }
	if((rc = grantpt(fdm)) < 0) { fprintf(stderr, "Erreur %d sur grantpt()\n", errno); return 1; }
	if((rc = unlockpt(fdm)) < 0) { fprintf(stderr, "Erreur %d sur unlockpt()\n", errno); return 1; }
	// Ouverture du PTY esclave
	fds = open(ptsname(fdm), O_RDWR);
	// Création d'un processus fils
	if (fork())
	{
	close(fds);
		/* Si notre entrée est un TTY, on laisse le TTY applicatif le gérer à sa guise. */
		struct termios infosStdin;
		if(isatty(0))
		{
			tcgetattr(0, &g_infosStdin);
			infosStdin = g_infosStdin;
			cfmakeraw(&infosStdin);
			tcsetattr(0, TCSANOW, &infosStdin);
		}
		maitre(fdm, fdm, premiereEtape);
		if(isatty(0))
			tcsetattr(0, TCSANOW, &g_infosStdin);
  }
  else
  {
    // Code du processus fils
    // Fermeture de la partie maitre du PTY
    close(fdm);
    // Le cote esclave du PTY devient l'entree et les sorties standards du fils
    // Fermeture de l'entrée standard (terminal courant)
    close(0);
    // Fermeture de la sortie standard (terminal courant)
    close(1);
    // Fermeture de la sortie erreur standard (terminal courant)
    close(2);
    // Le PTY devient l'entree standard (0)
    dup(fds);
    // Le PTY devient la sortie standard (1)
    dup(fds);
    // Le PTY devient la sortie erreur standard (2)
    dup(fds);
    // Maintenant le descripteur de fichier original n'est plus utile
    close(fds);

    // Le process courant devient un leader de session
    setsid();
    // Comme le process courant est un leader de session, La partie esclave du PTY devient sont terminal de contrôle
    // (Obligatoire pour les programmes comme le shell pour faire en sorte qu'ils gerent correctement leurs sorties)
    ioctl(0, TIOCSCTTY, 1);

    // Execution du programme
	execvp(argv[0], argv);
	return -1;
  }
  return 0;
} // main
