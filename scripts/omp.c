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
	S_SANS_TAMPON
};

enum
{
	I_PTY = -2,
	I_STDIN = -3
};

static int g_sansTampon = 0;
static int g_fermeEnFin = 1;

typedef struct Etape Etape;
struct Etape
{
	const char * attente;
	int pauseMilli;
	const char * saisie;
	Etape * suite;
	int vus; /* Nombre d'octets de l'attente déjà vus passer. */
	int injecteur;
};

int attends(int f, const char * attente)
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

		t += t2;
		bloc[t] = 0;

		if(strstr(bloc, attente))
		{
			fprintf(stdout, "%s", bloc);
			fflush(stdout);
			TRACE(stderr, "trouve\n");
			return 0;
		}
	}
}

/**
 * @return Si les octets closent l'attente: nombre d'octets consommé; sinon -1 si la chaîne a été absorbée mais que l'on reste en attente de cette étape.
 */
int injecteEnEtape(Etape * etape, char * octets, int n)
{
	int voulus = strlen(etape->attente);
	int reste = n;
	
	while(etape->vus < voulus)
	{
		/* On veut avancer dans la chaîne attendue à cette étape. */
		
		/* Déjà, a-t-on un octet à lire dans notre source? */
		
		if(--reste < 0)
			return -1;
		
		/* Bon, essayons de le faire correspondre au prochain octet attendu. */
		
		retente:
		if(*octets != etape->attente[etape->vus])
		{
			/* Si l'octet n'est pas le prochain attendu, on ne remet pas nécessairement notre état à 0; ainsi, si on attend abcabd, et qu'on reçoit abcabcabd, le second c arrivera alors que l'on aura déjà "vu" 5 caractères (abcab), mais le c ne correspondant pas au d alors attendu, on échoue à poursuivre plus loin, cependant on ne remet pas le compteur à 0, mais à 2, car le dernier ab passé (qui correspondait à attente[3..4]) correspond aussi à attente[0..1]. */
			/* On recherche donc le plus grand dernier segment déjà vu qui puisse être un segment de début. */
			while(--etape->vus >= 0)
			{
				if(memcmp(etape->attente, &etape->attente[etape->vus], etape->vus))
					goto retente;
			}
			/* Bon, si on était déjà acculé, et qu'on n'a pas trouvé, on ne trouvera pas plus en arrière. On sort, en laissant notre valeur à -1 pour qu'elle repasse à 0 juste après. */
		}
		++etape->vus;
		
		/* Celui-ci est passé (avec ou sans avancée, on s'en fiche). */
		
		++octets;
	}
	
	return reste;
}

void etapeControle(Etape * etape)
{
	struct termios t;
	
	switch((int)etape->saisie)
	{
		case (int)S_SANS_TAMPON:
			/* http://shtrom.ssji.net/skb/getc.html */
			tcgetattr(0, &t);
			t.c_lflag &= (~ICANON);
			tcsetattr(0, TCSANOW, &t); /* ATTENTION: ce faisant on perd même la mise en correspondance ^D -> fin de flux. À corriger, par exemple en insérant en fin d'étapes une étape avec un code qui ne sort jamais (étape finale) mais analyse chaque octet à la recherche d'un ^D, par lequel elle ferme l'entrée standard. */
			g_sansTampon = 1;
			break;
	}
}

Etape * pousseAuTube(Etape * etape)
{
	TRACE(stderr, "repéré sur le tube: %s\n", etape->attente);
	usleep(etape->pauseMilli * 1000);
	write(etape->injecteur, etape->saisie, strlen(etape->saisie));
	write(etape->injecteur, "\n", 1);
	return etape->suite;
}

Etape * injecteEnEtapes(Etape * etape, char * octets, int n)
{
	int nc;
	
	while(etape)
	{
		/* Traitement des étapes de contrôle. */
		
		if(!etape->attente)
		{
			etapeControle(etape);
			etape = etape->suite;
			continue;
		}
		
		if((nc = injecteEnEtape(etape, octets, n)) < 0)
			return etape;
		
		etape = pousseAuTube(etape);
		
		octets += nc;
		n -= nc;
	}
	
	return etape;
}

#define TBLOC 0x1000

#define O_CONTROLER 0x1
#define O_SURVEILLER 0x2

Etape * lire(fd_set * descrs, int * descr, int numBloc, char ** blocs, char ** pBlocs, int * restes, int opt, Etape * etapeCourante)
{
	int rc;
	
	if(*descr >= 0 && FD_ISSET(*descr, descrs))
	{
		if((rc = read(*descr, &pBlocs[numBloc][restes[numBloc]], TBLOC - (pBlocs[numBloc] - blocs[numBloc]) - restes[numBloc])) < 0)
		{
			fprintf(stderr, "Erreur %d sur read entree standard\n", errno);
			return etapeCourante;
		}
		
		if(rc > 0)
		{
			char fermetureForcee = 0;
			if(opt & O_CONTROLER)
			{
				/* Si on n'a pas de tampon, on n'a pas non plus de fermeture de notre flux d'entrée sur réception d'un ^D. On le gère. */
				/* À FAIRE: en fait il faudrait détecter LF suivi de ^D; sans cela le ^D est un caractère comme un autre. */
				if(g_sansTampon)
				{
					int rc2;
					for(rc2 = -1; ++rc2 < rc && pBlocs[numBloc][restes[numBloc] + rc2] != (char)0x4;) {}
					if(rc2 < rc)
					{
						fermetureForcee = 1;
						rc = rc2;
					}
				}
			}
			if(opt & O_SURVEILLER)
			{
				// À FAIRE: injecter après avoir dépilé le restes[1], pour que ce qu'on injecte en réponse apparaisse après l'invite qui a provoqué cette réponse.
				etapeCourante = injecteEnEtapes(etapeCourante, pBlocs[numBloc] + restes[numBloc], rc);
			}
			restes[numBloc] += rc;
			if(!fermetureForcee)
				return etapeCourante;
			/* else on est dans le cas fermeture de stdin, ci-dessous. */
		}
		
		TRACE(stderr, "-> Fermeture du %d\n", *descr);
		close(*descr);
		*descr = -1;
	}
	
	return etapeCourante;
}

void maitre(int fdm, int tube, Etape * etape)
{
	int e = 0;
	
	TRACE(stderr, "%d: stdin maître\n", e);
	TRACE(stderr, "%d: stdin appli\n", tube);
	TRACE(stderr, "%d: pty appli\n", fdm);
	
	/* Maintenant que l'on connaît les descripteurs de fichier réels, on peut brancher l'injecteur des étapes. */
	
	Etape * pEtape;
	for(pEtape = etape; pEtape; pEtape = pEtape->suite)
	{
		if(pEtape->attente)
		{
			switch(pEtape->injecteur)
			{
				case I_STDIN: pEtape->injecteur = tube; break;
				case I_PTY: pEtape->injecteur = fdm; break;
			}
		}
	}
	
	/* On passe les première étapes, avant ouverture du stdin maître vers le stdin appli. */
	
	while(etape && etape->attente)
	{
		etape->injecteur = fdm;
		attends(fdm, etape->attente);
		/* Les premières étapes sont généralement celles de demande de mot de passe: on les fournit au PTY plutôt qu'au stdin (s'ils sont différents l'un de l'autre). */
		etape = pousseAuTube(etape);
	}

	char blocs[2][TBLOC];
	int restes[2];
	int fmax;
	char * pBlocs[2];
	char * debutsBlocs[2];
int  rc;
  fd_set fd_in;
	fd_set etatsS;
	restes[0] = 0;
	restes[1] = 0;
	pBlocs[0] = debutsBlocs[0] = &blocs[0][0];
	pBlocs[1] = debutsBlocs[1] = &blocs[1][0];
    // Code du processus pere
    // Fermeture de la partie esclave du PTY
	while (fdm >= 0)
    {
		fmax = -1;
		TRACE(stderr, "-> (Attente de mouvement)\n");
      // Attente de données de l'entrée standard et du PTY maître
      FD_ZERO(&fd_in);
		if(e >= 0 && restes[0] < TBLOC) { FD_SET(e, &fd_in); if(fmax < e) fmax = e; TRACE(stderr, "attends données sur stdin\n");}
		if(fdm >= 0 && restes[1] < TBLOC) { FD_SET(fdm, &fd_in); if(fmax < fdm) fmax = fdm; TRACE(stderr, "attends données du fils\n");}
		FD_ZERO(&etatsS);
		if(restes[0]) { FD_SET(tube, &etatsS); if(fmax < tube) fmax = tube; TRACE(stderr, "attends place chez fils\n"); }
		if(restes[1]) { FD_SET(1, &etatsS); if(fmax < 1) fmax = 1; TRACE(stderr, "attends place sur stdout\n"); }
		rc = select(fmax + 1, &fd_in, &etatsS, NULL, NULL);
      switch(rc)
      {
        case -1 : fprintf(stderr, "Erreur %d sur select()\n", errno);
                  exit(1);
        default :
        {
			if (FD_ISSET(tube, &etatsS))
          {
				if((rc = write(tube, pBlocs[0], restes[0])) > 0)
            {
					if((restes[0] -= rc) <= 0)
						pBlocs[0] = &blocs[0][0];
					else
						pBlocs[0] += rc;
					TRACE(stderr, "   Transmis: %d\n", rc);
				}
				if(e < 0 && !restes[0])
					close(tube);
            }
			// S'il y a des donnees sur le PTY maitre
			if (FD_ISSET(1, &etatsS))
			{
				if((rc = write(1, pBlocs[1], restes[1])) > 0)
				{
					if((restes[1] -= rc) <= 0)
						pBlocs[1] = &blocs[1][0];
            else
						pBlocs[1] += rc;
					TRACE(stderr, "   Transmis: %d\n", rc);
				}
			}
			// S'il y a des donnees sur l'entree standard
				etape = lire(&fd_in, &e, 0, debutsBlocs, pBlocs, restes, O_CONTROLER, etape);
				etape = lire(&fd_in, &fdm, 1, debutsBlocs, pBlocs, restes, O_SURVEILLER, etape);
				
				/* Si plus d'étape dans le scénario, on considère le stdin terminé (sauf si l'appelant a demandé explicitement à maintenir ouvert à la fin). */
				if(!etape && g_fermeEnFin && isatty(0))
				{
					TRACE(stderr, "-> Fermeture du stdin maître (par fin du scénario)\n");
					close(0);
					e = -1;
				}
				if(e < 0 && tube >= 0 && !restes[0])
				{
					TRACE(stderr, "-> Fermeture du stdin appli (notre stdin étant fermé)\n");
					close(tube);
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
		else if(strcmp(argv[0], "--") == 0)
		{
			etapes[0] = (Etape *)malloc(sizeof(Etape));
			etapes[0]->attente = NULL;
			etapes[0]->saisie = (char *)S_SANS_TAMPON;
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
	int tube[2]; // Pour faire suivre le stdin au sous-process.
	if((rc = pipe(&tube[0])) < 0) { fprintf(stderr, "Erreur %d sur pipe()\n", errno); return 1; }
	// Création d'un processus fils
	if (fork())
	{
	close(tube[0]);
	close(fds);
	maitre(fdm, tube[1], premiereEtape);
  }
  else
  {
	close(tube[1]);
  struct termios slave_orig_term_settings; // Saved terminal settings
  struct termios new_term_settings; // Current terminal settings
    // Code du processus fils
    // Fermeture de la partie maitre du PTY
    close(fdm);
    // Sauvegarde des parametre par defaut du PTY esclave
    rc = tcgetattr(fds, &slave_orig_term_settings);
    // Positionnement du PTY esclave en mode RAW
    new_term_settings = slave_orig_term_settings;
    cfmakeraw (&new_term_settings);
    tcsetattr (fds, TCSANOW, &new_term_settings);
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
	close(0);
	dup(tube[0]);
	execvp(argv[0], argv);
	return -1;
  }
  return 0;
} // main
