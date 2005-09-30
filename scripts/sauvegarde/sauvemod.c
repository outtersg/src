/* Compil:
cc -o ~/bin/sauvemod ~/src/scripts/sauvegarde/sauvemod.c -I ~/src/c -framework CoreFoundation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/errno.h>
#include <sys/syslimits.h>
#include <sys/wait.h>
#import <CoreFoundation/CFDictionary.h>
#import <CoreFoundation/CFString.h>
#include <Std/Tableau.h>

#define DEB if(0) {
#define EB(x) x:
#define FEB }

#define PREPERR int _erreur = 0;
#define ERR(x) { if(errno) fprintf(stderr, "### %d: %s\n", __LINE__, strerror(errno)); _erreur = 1; goto x; }
#define SIERR if(_erreur)

typedef char * Chaine;
DECLARE_TABLEAU(Chaine)
IMPLEMENTE_TABLEAU(Chaine)

/*- unEnsemble ---------------------------------------------------------------*/

struct unEnsemble
{
	char * nom;
	char * emplacement;
	unTableauChaine * derniers;
	char * dateDernier;
};
typedef struct unEnsemble unEnsemble;

unEnsemble * unEnsemble_nouveau()
{
	PREPERR
	unEnsemble * retour;
	
	if(!(retour = (unEnsemble *)malloc(sizeof(unEnsemble)))) ERR(eMem);
	if(!(retour->derniers = unTableauChaine_nouveau())) ERR(eDerniers);
	retour->emplacement = NULL;
	retour->dateDernier = NULL;
	return retour;
	
	unTableauChaine_detruire(retour->derniers);
	EB(eDerniers)
	free(retour);
	EB(eMem)
	return NULL;
}

int unEnsemble_ajouterDernier(unEnsemble * e, char * dernier)
{
	char * copie;
	char ** ptr;
	if(!(copie = (char *)malloc(strlen(dernier) + 1))) return -1;
	if(!(ptr = unTableauChaine_ajouter(e->derniers))) { free(copie); return -1; }
	*ptr = copie;
	strcpy(copie, dernier);
	return 0;
}

void unEnsemble_viderDerniers(unEnsemble * e)
{
	int n;
	for(n = unTableauChaine_taille(e->derniers); --n >= 0;)
		free(*unTableauChaine_element(e->derniers, n));
	unTableauChaine_vider(e->derniers);
}

void unEnsemble_detruire(unEnsemble * e)
{
	unTableauChaine_detruire(e->derniers);
}

/*- Variables globales -------------------------------------------------------*/

unEnsemble * g_ensemble;
char * g_destination;
char g_entreeFournie;
char g_entreeSepareeParDesNuls;
char g_sepSortie;
char g_reinitialiserSource;
char g_traiterListes; // Sauvegarde fichier par fichier, ou par lots.

char * g_argsFind[] = { "find", ".", "-type", "f", "-print0", NULL };
char * g_argsSort[] = { "sort", "-n", "-k", "1", NULL };
char * g_argsDatef[] = { "xargs", "datef", NULL };
char * g_argsDatef0[] = { "xargs", "-0", "datef", NULL };
char * g_argsMkdir[] = { "mkdir", "-p", ".", NULL };
char * g_argsCp[] = { "cp", "-Rp", ".", ".", NULL }; /* À FAIRE: et pour les ressources? *//* Le -R pour qu'il ne suive pas les liens symboliques */
/* Copie massive qui doit prendre en entrée des chemins séparés par des
 * caractères nuls, et renvoyer le nombre d'éléments qu'elle a pu copier
 * (donc un code de sortie de 0 n'est pas terrible!). */
char * g_argsExode[] = { "cpcd", "-0", ".", NULL }; /* À FAIRE: et pour les ressources? *//* Le -R pour qu'il ne suive pas les liens symboliques */

#define TAILLE_DATE 23 /* 4a2m2j2h2m2s3m3µ3n  */
	
void auSecours(char * nomProgramme)
{
	char * ptr;
	if(!(ptr = strrchr(nomProgramme, '/')))
		ptr = nomProgramme;
	else
		++ptr;
	fprintf(stderr, "# %s\n", ptr);
	fprintf(stderr, "# Sauvegarde incrémentale\n");
	fprintf(stderr, "# © Guillaume Outters 2004\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Utilisation: %s [-0] [-print0] [-f] <nom d'ensemble> [<destination>]\n", ptr);
	fprintf(stderr, "  <nom d'ensemble>: si l'ensemble n'existe pas, il est créé à partir du\n");
	fprintf(stderr, "                    répertoire courant. Sinon tous les fichiers du\n");
	fprintf(stderr, "                    répertoire de l'ensemble plus récents que le dernier\n");
	fprintf(stderr, "                    enregistré sont archivés.\n");
	fprintf(stderr, "  <destination>:    répertoire-racine de la sauvegarde. S'il n'est pas spécifié,\n");
	fprintf(stderr, "                    la liste des fichiers à modifier est simplement affichée.\n");
	fprintf(stderr, "  -0:               si le chemin des fichiers à archiver est envoyé par l'entrée\n");
	fprintf(stderr, "                    standard du programme, ils sont séparés par des caractères\n");
	fprintf(stderr, "                    nuls.\n");
	fprintf(stderr, "  -print0:          en sortie, les différents fichiers sont séparés par un\n");
	fprintf(stderr, "                    caractère nul plutôt qu'un retour.\n");
	fprintf(stderr, "                    standard du programme, ils sont séparés par des caractères\n");
	fprintf(stderr, "                    nuls.\n");
	fprintf(stderr, "  -f:               réinitialise le répertoire source (utile s'il a été\n");
	fprintf(stderr, "                    renommé).\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Un ensemble représente une arborescence archivée; sont archivés les fichiers de.\n");
	fprintf(stderr, "cette arborescence dont la date de modification est postérieure à celle du\n");
	fprintf(stderr, "dernier fichier archivé la dernière fois, dans une arborescence miroir où les.\n");
	fprintf(stderr, "sous-dossiers sont créés au besoin, lorsqu'un fichier du sous-dossier original.\n");
	fprintf(stderr, "doit être archivé.\n");
	fprintf(stderr, "Si l'entrée standard du programme n'est pas un TTY, il est considéré qu'y sont\n");
	fprintf(stderr, "les chemins (relatifs) des fichiers à éventuellement archiver.\n");
	
	exit(1);
}

int analyserParams(char ** argv)
{
	g_ensemble->nom = NULL;
	g_destination = NULL;
	g_entreeSepareeParDesNuls = 0;
	g_sepSortie = '\n';
	g_reinitialiserSource = 0;
	g_traiterListes = 1;
	while(*++argv)
	{
		if(strcmp(*argv, "-0") == 0)
			g_entreeSepareeParDesNuls = 1;
		else if(strcmp(*argv, "-print0") == 0)
			g_sepSortie = 0;
		else if(strcmp(*argv, "-f") == 0)
			g_reinitialiserSource = 1;
		else if(!g_ensemble->nom)
			g_ensemble->nom = *argv;
		else if(!g_destination)
			g_destination = *argv;
		else
			return 1;
	}
	return g_ensemble->nom ? 0 : -1;
}

char * chaine(CFStringRef chaine)
{
	int taille;
	char * r;
	taille = CFStringGetMaximumSizeForEncoding(CFStringGetLength(chaine), kCFStringEncodingUTF8);
	if(!(r = (char *)malloc(taille + 1))) return NULL;
	if(CFStringGetLength(chaine) == 0)
		r[0] = 0;
	else if(!CFStringGetCString(chaine, r, taille, kCFStringEncodingUTF8)) { fprintf(stderr, "%d: %s\n", CFStringGetLength(chaine), chaine); free(r); return NULL; }
	return r;
}

int lireDico(CFDictionaryRef dico, char * nom, char ** dest)
{
	PREPERR
	CFStringRef chaine;
	CFIndex taille;
	CFStringRef nom2;
	
	if(!(nom2 = CFStringCreateWithCString(NULL, nom, kCFStringEncodingUTF8))) ERR(eChaine);
	if(!(chaine = CFDictionaryGetValue(dico, nom2))) ERR(ePasLa);
	
	taille = CFStringGetMaximumSizeForEncoding(CFStringGetLength(chaine), kCFStringEncodingUTF8);
	if(!(*dest = (char *)malloc(taille + 1))) ERR(eMem);
	if(CFStringGetLength(chaine) == 0)
		(*dest)[0] = 0;
	else if(!CFStringGetCString(chaine, *dest, taille, kCFStringEncodingUTF8)) { fprintf(stderr, "%d: %s\n", CFStringGetLength(chaine), chaine); ERR(eConv); }
	
	/* Ménage */
	
	EB(eConv)
	SIERR
	{
		free(*dest);
		*dest = NULL;
	}
	EB(eMem)
	EB(ePasLa)
	CFRelease(nom2);
	EB(eChaine)
	
	SIERR return -1;
	return 0;
}

int lireDicoTableauChaine(CFDictionaryRef dico, char * nom, unTableauChaine * dest)
{
	PREPERR
	CFStringRef nom2;
	CFArrayRef tableau;
	CFIndex n;
	CFStringRef chaine;
	CFIndex taille;
	char * ptr;
	char ** ptrptr;
	
	if(!(nom2 = CFStringCreateWithCString(NULL, nom, kCFStringEncodingUTF8))) ERR(eChaine);
	if(!(tableau = CFDictionaryGetValue(dico, nom2))) ERR(ePasLa);
	if(CFGetTypeID(tableau) != CFArrayGetTypeID()) ERR(ePasBon);
	
	for(n = CFArrayGetCount(tableau); --n >= 0;)
	{
		chaine = CFArrayGetValueAtIndex(tableau, n); /* On ne va même pas prendre la peine de faire un CFRetain */
		taille = CFStringGetMaximumSizeForEncoding(CFStringGetLength(chaine), kCFStringEncodingUTF8);
		if(!(ptr = (char *)malloc(taille + 1))) ERR(ePendant);
		if(!CFStringGetCString(chaine, ptr, taille, kCFStringEncodingUTF8)) ERR(ePendant);
		if(!(ptrptr = unTableauChaine_ajouter(dest))) { free(ptr); ERR(ePendant); }
		*ptrptr = ptr;
	}
	
	/* Ménage */
	
	EB(ePendant)
	
	EB(ePasBon)
	
	EB(ePasLa)
	
	CFRelease(nom2);
	EB(eChaine)
	
	SIERR return -1;
	return 0;
}

int lirePrefsEnsemble(unEnsemble * ensemble)
{
	PREPERR
	CFDictionaryRef dico;
	CFStringRef nom;
	
	nom = CFStringCreateWithCString(NULL, ensemble->nom, kCFStringEncodingUTF8); /* À FAIRE: n'y a-t-il pas un encodage spécial "encodage du système de fichiers" ? */
	dico = (CFDictionaryRef)CFPreferencesCopyAppValue(nom, CFSTR("net.outters.sauvemod"));
	CFRelease(nom);
	
	if(dico && CFGetTypeID(dico) == CFDictionaryGetTypeID())
	{
		lireDico(dico, "emplacement", &ensemble->emplacement);
		lireDico(dico, "dateDernier", &ensemble->dateDernier);
		if(ensemble->dateDernier && strlen(ensemble->dateDernier) != TAILLE_DATE) { fprintf(stderr, "# Préférences endommagées: la date de dernière sauvegarde n'est pas au bon format\n"); ensemble->dateDernier = NULL; ERR(eTaille); }
		lireDicoTableauChaine(dico, "derniers", ensemble->derniers);
	}
	
	EB(eTaille)
	
	if(dico) CFRelease(dico);
	
	SIERR return -1;
	return 0;
}

int ecrirePrefsEnsemble(unEnsemble * ensemble)
{
	PREPERR
	CFDictionaryRef dico;
	CFStringRef nom;
	CFStringRef cles[3];
	CFPropertyListRef valeurs[3];
	int n;
	CFPropertyListRef * tableauDerniers;
	
	if(!ensemble->dateDernier || !strlen(ensemble->dateDernier)) goto eRienAFaire;
	cles[0] = CFSTR("emplacement");
	cles[1] = CFSTR("dateDernier");
	cles[2] = CFSTR("derniers");
	if(!(valeurs[0] = CFStringCreateWithCString(NULL, ensemble->emplacement, kCFStringEncodingUTF8))) ERR(eEmplacement);
	if(!(valeurs[1] = CFStringCreateWithCString(NULL, ensemble->dateDernier, kCFStringEncodingUTF8))) ERR(eDate);
	tableauDerniers = (CFPropertyListRef *)alloca((n = unTableauChaine_taille(ensemble->derniers)) * sizeof(CFPropertyListRef));
	bzero(tableauDerniers, n * sizeof(CFPropertyListRef));
	while(--n >= 0)
		if(!(tableauDerniers[n] = CFStringCreateWithCString(NULL, *unTableauChaine_element(ensemble->derniers, n), kCFStringEncodingUTF8))) ERR(eTableauDerniers);
	if(!(valeurs[2] = CFArrayCreate(NULL, tableauDerniers, unTableauChaine_taille(ensemble->derniers), &kCFTypeArrayCallBacks))) ERR(eTableauDerniers);
	//valeurs[2] = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	//CFArrayAppendValue((CFMutableArrayRef)valeurs[2], CFSTR("bla"));
	
	if(!(dico = CFDictionaryCreate(NULL, (const void **)cles, valeurs, 3, NULL, &kCFTypeDictionaryValueCallBacks))) ERR(eDico);
	
	if(!(nom = CFStringCreateWithCString(NULL, ensemble->nom, kCFStringEncodingUTF8))) ERR(eNom);
	CFPreferencesSetAppValue(nom, dico, CFSTR("net.outters.sauvemod"));
	
	if(!CFPreferencesAppSynchronize(CFSTR("net.outters.sauvemod"))) fprintf(stderr, "### Impossible d'enregistrer les préférences.\n");
	
	CFRelease(nom);
	EB(eNom)
	
	CFRelease(dico);
	EB(eDico)
	
	CFRelease(valeurs[2]);
	EB(eTableauDerniers)
	for(n = unTableauChaine_taille(ensemble->derniers); --n >= 0;)
		if(tableauDerniers[n])
			CFRelease(tableauDerniers[n]);
	
	CFRelease(valeurs[1]);
	EB(eDate)
	
	CFRelease(valeurs[0]);
	EB(eEmplacement)
	
	EB(eRienAFaire)
	
	SIERR return -1;
	return 0;
}

/* Lance un sous-process et balance sa sortie vers un descripteur de fichier
 * particulier; renvoie le descripteur de fichier qui permet d'écrire dessus. */
/* COPIE: lancer2() */

int lancer(char ** args, int entree, int sortie)
{
	PREPERR
	pid_t fils;
	int monEntree[2];
	if(entree < 0)
	{
		if(pipe(&monEntree[0]) != 0) ERR(eEntree);
		entree = monEntree[0];
	}
	else
		monEntree[0] = monEntree[1] = -1;
	switch((fils = fork()))
	{
		case 0:
			close(1); /* La sortie standard de ce process… */
			dup(sortie); /* … doit aller dans notre tube. */
			close(sortie);
			if(entree != 0)
			{
				close(0);
				dup(entree);
				close(entree);
			}
			if(monEntree[1] >= 0)
				close(monEntree[1]);
			if(execvp(args[0], args) != 0) ERR(eExec);
			_exit(1);
			break;
		case -1:
			return -1;
		default:
			close(entree);
			close(sortie);
			break;
	}
	
	/* Ménage */
	
	EB(eExec)
	
	SIERR { if(monEntree[0] >= 0) close(monEntree[0]); if(monEntree[1] >= 0) close(monEntree[1]); }
	EB(eEntree)
	
	SIERR return -1;
	return monEntree[1] >= 0 ? monEntree[1] : 1;
}

/* Lance un process en branchant ses E/S sur des machins passés en paramètres;
 * renvoie le pid lancé. */
/* COPIE: lancer() */

int lancer2(char ** args, int * ptrEntree, int * ptrSortie)
{
	PREPERR
	pid_t fils;
	int entree, sortie;
	int tubes[4]; // 0: fils de père; 1: père à fils; 2: père de fils; 3: fils à père.
	int i;
	
	for(i = 4; --i >= 0;)
		tubes[i] = -1;
	if(ptrEntree)
	{
		if((entree = *ptrEntree) < 0)
		{
			if(pipe(&tubes[0]) != 0) ERR(eEntree);
			*ptrEntree = tubes[1];
			entree = tubes[0];
		}
	}
	else
		entree = -1;
	if(ptrSortie)
	{
		if((sortie = *ptrSortie) < 0)
		{
			if(pipe(&tubes[2]) != 0) ERR(eEntree);
			*ptrSortie = tubes[2];
			sortie = tubes[3];
		}
	}
	else
		sortie = -1;
	switch((fils = fork()))
	{
		case 0:
			if(sortie != 1)
			{
				close(1); /* La sortie standard de ce process… */
				if(sortie >= 0)
				{
					dup(sortie); /* … doit aller dans notre tube. */
					close(sortie);
				}
			}
			if(entree != 0)
			{
				close(0);
				if(entree >= 0)
				{
					dup(entree);
					close(entree);
				}
			}
			if(tubes[1] >= 0)
				close(tubes[1]);
			if(tubes[2] >= 0)
				close(tubes[2]);
			if(execvp(args[0], args) != 0) ERR(eExec);
			_exit(1);
			break;
		case -1:
			return -1;
		default:
			close(entree);
			close(sortie);
			break;
	}
	
	/* Ménage */
	
	EB(eExec)
	
	EB(eEntree)
	SIERR { for(i = 4; --i >= 0;) if(tubes[i] >= 0) close(tubes[i]); }
	
	SIERR return -1;
	return fils;
}

int attendre(char ** args)
{
	pid_t fils;
	int r;
	
	switch((fils = fork()))
	{
		case 0:
			execvp(args[0], args);
			_exit(1);
			break;
		case -1:
			return -1;
	}
	
	waitpid(fils, &r, 0);
	return WIFEXITED(r) && !WEXITSTATUS(r) ? 0 : -1;
}

int rechercher(unEnsemble * ensemble)
{
	PREPERR
	int desc[2];
	int f;
	
	if(pipe(&desc[0]) != 0) ERR(eTube);
	
	f = desc[1];
	if((f = lancer(g_argsSort, -1, f)) < 0) ERR(eTri);
	if((f = lancer(g_entreeSepareeParDesNuls || !g_entreeFournie ? g_argsDatef0 : g_argsDatef, g_entreeFournie ? 0 : -1, f)) < 0) ERR(eDatation);
	if(!g_entreeFournie)
		if((f = lancer(g_argsFind, -1, f)) < 0) ERR(eRecherche);
	
	/* Ménage */
	
	EB(eRecherche)
	
	EB(eDatation)
	
	EB(eTri)
	
	SIERR { close(desc[0]); close(desc[1]); }
	EB(eTube)
	
	SIERR return -1;
	return desc[0];
}

#define TAILLE_LECTURE 0x4000
struct uneLecture
{
	int fichier;
	char mem[TAILLE_LECTURE];
	char * courant;
	char * fin;
};
typedef struct uneLecture uneLecture;

void initialiserLecture(uneLecture * lecture, int fichier)
{
	lecture->fichier = fichier;
	lecture->courant = lecture->fin = &lecture->mem[0];
}

#define E_FINI ((char *)0)
#define E_FORMAT ((char *)-1)
#define E_FICHIER ((char *)-2)
/* Lit lecture jusqu'au séparateur ou au caractère de synchro, sur tailleMax
 * caractères. Le résultat est soit directement issu de lecture->mem, soit dest
 * après y avoir copié la chaîne lue.
 * En cas de dépassement, E_FORMAT est renvoyée et lecture->courant placé sur le
 * caractère suivant le prochain retour à la ligne. */
char * remplir(uneLecture * lecture, char * dest, int tailleMax, char sep, char sepSync)
{
	char * ptr;
	char * destCourant; /* Si NULL, on travaille directement dans lecture->mem; sinon on a commencé à remplir dest (par memcpy), il faut donc continuer dans ce bloc pour renvoyer à l'utilisateur une chaîne contigüe. */
	int n;
	
	destCourant = NULL;
	ptr = lecture->courant;
	while(1)
	{
		for(; ptr < lecture->fin; ++ptr)
			if(*ptr == sep)
			{
				if(destCourant)
				{
					if(ptr - lecture->courant + destCourant - dest > tailleMax) goto sync;
					/* On complète ce qu'on avait mis de côté, et on le renvoie. */
					memcpy(destCourant, lecture->courant, ptr - lecture->courant);
					destCourant += ptr - lecture->courant;
					*destCourant++ = 0;
					lecture->courant = ++ptr;
					return dest;
				}
				else
				{
					/* On renvoie le contenu de lecture->mem, après y avoir
					 * ajouté un petit caractère nul. */
					destCourant = lecture->courant;
					*ptr = 0;
					lecture->courant = ptr + 1;
					if(ptr - destCourant > tailleMax) goto sync;
					return destCourant;
				}
			}
			else if(*ptr == sepSync)
			{
				lecture->courant = ptr + 1;
				return E_FORMAT;
			}
		if(ptr < &lecture->mem[TAILLE_LECTURE]) /* Si on peut lire le fichier à la suite de notre bloc déjà alloué. */
		{
re1:		if((n = read(lecture->fichier, lecture->fin, TAILLE_LECTURE - (lecture->fin - lecture->mem))) == 0)
			{
				if(ptr == lecture->courant && !destCourant) return E_FINI; /* Si on n'est pas en train de lire un champ, on peut expliquer que c'est terminé… */
				*lecture->fin++ = sepSync; /* … sinon on simule la fin du champ. */
			}
			else if(n < 0)
			{
				if(errno == EINTR) goto re1;
				lecture->courant = ptr;
				return E_FICHIER;
			}
			else
				lecture->fin += n;
		}
		else /* On va lire un nouveau bloc */
		{
			/* Recopie de ce qui avait été déjà lu */
			
			if(!destCourant) destCourant = dest;
			if(ptr - lecture->courant + destCourant - dest > tailleMax) goto sync;
			memcpy(destCourant, lecture->courant, ptr - lecture->courant);
			destCourant += ptr - lecture->courant;
			
re2:		if((n = read(lecture->fichier, lecture->mem, TAILLE_LECTURE)) < 0) /* Si ça vaut 0, on laisse faire le prochain tour de boucle. */
			{
				if(errno == EINTR) goto re2;
				lecture->courant = lecture->fin = ptr;
				return E_FICHIER;
			}
			else
				lecture->fin = (ptr = lecture->courant = lecture->mem) + n;
		}
	}
	
	/* Lecture sans état d'âme jusqu'au prochain caractère de resynchro */
	
sync:
	while(1)
	{
		for(; ptr < lecture->fin; ++ptr)
			if(*ptr == sepSync)
			{
				lecture->courant = ptr + 1;
				return E_FORMAT;
			}
re3:	if((n = read(lecture->fichier, lecture->mem, TAILLE_LECTURE)) <= 0)
		{
			if(errno == EINTR) goto re3;
			return n < 0 ? E_FICHIER : E_FORMAT;
		}
		lecture->fin = (ptr = lecture->courant = lecture->mem) + n;
	}
}

/* Lit dans un fichier la prochaine entrée "fichier", et renvoie des pointeurs
 * sur sa date et son chemin. Les pointeurs résultants ne doivent pas être
 * désalloués (ils tapent dans de la mémoire réservée par lire). Renvoie -1, 0
 * ou 1 (erreur de fichier, fin, une entrée). */
int lire(uneLecture * lecture, char ** ptrDate, char ** ptrChemin)
{
	static char g_date[TAILLE_DATE + 1];
	static char g_chemin[PATH_MAX + 1];
	
	char * ptr;
	
re:
	if((ptr = remplir(lecture, g_date, TAILLE_DATE, ' ', '\n')) == E_FICHIER)
		return -1;
	else if(ptr == E_FORMAT)
	{
		fprintf(stderr, "### Erreur de format\n");
		goto re;
	}
	else if(ptr == E_FINI)
		return 0;
	if(strlen(ptr) != TAILLE_DATE) goto re;
	*ptrDate = ptr;
	
	if((ptr = remplir(lecture, g_chemin, PATH_MAX, '\n', '\n')) == E_FICHIER)
		return -1;
	else if(ptr == E_FORMAT)
	{
		fprintf(stderr, "### Erreur de format\n");
		goto re;
	}
	*ptrChemin = ptr;
	return 1;
}

int traiterListe(char ** chemins, char ** dates, int faire, unEnsemble * dest)
{
	PREPERR
	char ** ptrptr;
	char ** pplent;
	char ** ppfin;
	int balance;
	int exode;
	int r;
	int n;
	char * chaine;
	int comp;
	
	if(!faire)
	{
		for(ptrptr = chemins; *ptrptr; ++ptrptr)
			fprintf(stdout, "%s%c", *ptrptr, g_sepSortie);
		return ptrptr - chemins;
	}
	
	/* On n'écrit jamais plus de 127 choses à la fois, car le processus doit
	 * nous renvoyer par son code de sortie le nombre de choses écrites, dont on
	 * ne peut récupérer que les 8 derniers bits par WEXITSTATUS. */
	
	n = 0;
	pplent = chemins;
	while(*pplent)
	{
		balance = -1;
		if((exode = lancer2(g_argsExode, &balance, NULL)) < 0) ERR(eExode);
		
		for(ptrptr = pplent; *ptrptr && ptrptr < &pplent[127]; ++ptrptr)
			write(balance, *ptrptr, strlen(*ptrptr) + 1);
		
		close(balance);
		balance = -1;
		
		waitpid(exode, &r, 0);
		if(WIFEXITED(r))
			r = WEXITSTATUS(r);
		else
			r = -1;
		
		if(r > (ptrptr - pplent)) // Mythomane, va!
			r = ptrptr - pplent;
		ppfin = &pplent[r];
		for(; pplent < ppfin; ++pplent)
			fprintf(stdout, "%s%c", *pplent, g_sepSortie);
		
		/* Ménage */
		
		if(balance >= 0) close(balance);
		EB(eExode)
		
		if(r < 0) // Erreur!
		{
			errno = ECANCELED;
			n = -1;
			break;
		}
		n += r;
		if(ppfin < ptrptr) // On n'est pas allé jusqu'au bout.
			break;
	}
	
	/* On fait avancer notre Ensemble jusqu'au dernier qui a pu être copié */
	
	if(n > 0)
	{
		if(strcmp(dest->dateDernier, dates[n - 1]) != 0)
		{
			comp = 1;
			unEnsemble_viderDerniers(dest);
		}
		else
			comp = 0;
		for(r = n; --r >= 0 && strcmp(dates[r], dates[n - 1]) == 0;) {}
		while(++r < n)
			if(unEnsemble_ajouterDernier(dest, chemins[r]) != 0) ERR(eCopie);
		if(comp)
			strcpy(dest->dateDernier, dates[n - 1]);
		
		EB(eCopie)
		
		SIERR(unEnsemble_viderDerniers(dest));
	}
	
	SIERR return -1;
	return n;
}

#define TAILLE_LISTE 64 /* Pas plus de 127, chercher dans le source pourquoi. */
static char g_dates[TAILLE_LISTE + 1][TAILLE_DATE + 1];
static char g_chemins[TAILLE_LISTE + 1][PATH_MAX + 1];
static char * g_ptrDates[TAILLE_LISTE + 1];
static char * g_ptrChemins[TAILLE_LISTE + 1];
static int initChemins()
{
	int z;
	for(z = TAILLE_LISTE; --z >= 0;)
	{
		g_ptrDates[z] = &g_dates[z][0];
		g_ptrChemins[z] = &g_chemins[z][0];
	}
	g_ptrDates[TAILLE_LISTE] = NULL;
	g_ptrChemins[TAILLE_LISTE] = NULL;
	return 0;
}

int traiter(char * chemin, char * date, char * suiteDest, int tailleSuiteDest, unEnsemble * dest)
{
	static int g_machinCourant = -1;
	
	int comp;
	
	/* Si on travaille par lots, on accumule */
	
	if(g_traiterListes)
	{
		if(g_machinCourant < 0)
			g_machinCourant = initChemins();
		if(chemin)
		{
			strcpy(&g_chemins[g_machinCourant][0], chemin);
			strcpy(&g_dates[g_machinCourant][0], date);
		}
		if(!chemin || (++g_machinCourant >= TAILLE_LISTE))
		{
			g_ptrChemins[g_machinCourant] = NULL;
			g_ptrDates[g_machinCourant] = NULL; // Clôture de la liste.
			comp = traiterListe(g_ptrChemins, g_ptrDates, suiteDest != NULL, dest); // Écriture.
			g_ptrDates[g_machinCourant] = &g_dates[g_machinCourant][0];
			g_ptrChemins[g_machinCourant] = &g_chemins[g_machinCourant][0];
			comp = comp < 0 ? -1 : comp == g_machinCourant ? 0 : 1;
			if(comp == 1) errno = ECANCELED; // En fait il faudrait adopter la même norme pour traiter(), et ensuite ne plus afficher de message d'erreur pour un retour > 0 (échec de l'opération, mais on s'y attendait).
			g_machinCourant = 0;
			return comp;
		}
		return 0;
	}
	
	/* Fonctionnement un par un */
	
	PREPERR
	char * chaine;
	
	fprintf(stdout, "%s%c", chemin, g_sepSortie);
	if(!suiteDest) return 0;
	
	/* À la moindre erreur on arrête pour que la prochaine sauvegarde reparte au
	 * premier fichier non sauvegardé. */
	if(strlen(chemin) > tailleSuiteDest) ERR(err);
	strcpy(suiteDest, chemin);
	chaine = strrchr(suiteDest - 1, '/'); /* On sait que juste avant suiteDest on a un '/', qui servira de butoir si nécessaire. */
	*chaine = 0;
	if(attendre(g_argsMkdir) != 0) ERR(err);
	g_argsCp[2] = chemin;
	if(attendre(g_argsCp) != 0) ERR(err);
	if(strcmp(dest->dateDernier, date) != 0)
	{
		comp = 1;
		unEnsemble_viderDerniers(dest);
	}
	else
		comp = 0;
	if(unEnsemble_ajouterDernier(dest, chemin) != 0) ERR(err);
	if(comp)
		strcpy(dest->dateDernier, date);
	
	EB(err)
	SIERR return -1;
	return 0;
}

#define AVANT 0
#define PENDANT 1
#define APRES 2

int main(int argc, char ** argv)
{
	PREPERR
	int f;
	char b[4096];
	char c;
	char * chaine;
	uneLecture g_lecture;
	char * date;
	char * chemin;
	int etat;
	int comp;
	char dest[PATH_MAX + 1];
	char * suiteDest;
	int tailleSuiteDest;
	
	signal(SIGPIPE,SIG_IGN); // Parfois nos fils quitteront en catimini, ne leur en voulons pas, ils sont jeunes, c'est comme ça.
	
	if(!(g_ensemble = unEnsemble_nouveau())) ERR(eEnsemble);
	if(analyserParams(argv) != 0) auSecours(argv[0]);
	
	if(lirePrefsEnsemble(g_ensemble) != 0) ERR(eLecture);
	
	g_entreeFournie = !isatty(0);
	
	if(g_reinitialiserSource && g_ensemble->emplacement)
	{
		free(g_ensemble->emplacement);
		g_ensemble->emplacement = NULL;
	}
	
	if(!g_ensemble->emplacement)
	{
		chaine = getenv("PWD");
		if(!g_entreeFournie)
		{
			fprintf(stderr, "L'ensemble %s n'a pas encore été créé. Voulez-vous le créer à partir du répertoire %s ? ", g_ensemble->nom, chaine);
			c = fgetc(stdin);
			switch(c)
			{
				case 'o':
				case 'O':
				case 'y':
				case 'Y':
					break;
				default:
					ERR(eRien);
			}
		}
		
		if(!(g_ensemble->emplacement = (char *)malloc(strlen(chaine) + 1))) ERR(eAlloc);
		strcpy(g_ensemble->emplacement, chaine);
	}
	else if(g_entreeFournie) /* Si l'entrée que l'on reçoit contient tous les fichiers, il s'agit probablement de fichiers relatifs, on vérifie qu'ils sont calculés depuis le même endroit que la dernière fois. */
	{
		if(strcmp(getenv("PWD"), g_ensemble->emplacement) != 0) { fprintf(stderr, "### Le répertoire courant n'est pas celui à partir duquel avait été faite la dernière sauvegarde."); ERR(eCd); }
	}
	else
		if(chdir(g_ensemble->emplacement) != 0) ERR(eCd);
	if(!g_ensemble->dateDernier)
		if(!(g_ensemble->dateDernier = (char *)malloc(TAILLE_DATE + 1))) ERR(eMemDateDernier);
	
	if((f = rechercher(g_ensemble)) < 0) ERR(eRecherche);
	
	/* Le fichier nous sort des lignes contenant une date suivie d'un espace
	 * suivi d'un nom de fichier. En cas d'erreur on essaie de se rattraper à un
	 * retour à la ligne. */
	
	initialiserLecture(&g_lecture, f);
	
	if(g_destination)
	{
		g_argsMkdir[2] = dest;
		g_argsCp[3] = dest;
		g_argsExode[2] = dest;
		strcpy(dest, g_destination);
		tailleSuiteDest = strlen(dest);
		suiteDest = &dest[tailleSuiteDest];
		if((tailleSuiteDest = PATH_MAX - tailleSuiteDest - 1) <= 0) ERR(ePasAssezGrand);
		*suiteDest = '/';
		*++suiteDest = 0;
	}
	else
		suiteDest = NULL;
	
	etat = g_ensemble->dateDernier ? AVANT : APRES;
	while(lire(&g_lecture, &date, &chemin) > 0)
		switch(etat)
		{
			case AVANT:
				if((comp = strcmp(date, g_ensemble->dateDernier)) < 0)
					break;
				if(comp > 0) { etat = APRES; goto ap; }
				etat = PENDANT;
				/* Et on passe à PENDANT */
			case PENDANT:
				if((comp = strcmp(date, g_ensemble->dateDernier)) == 0)
				{
					for(comp = unTableauChaine_taille(g_ensemble->derniers); --comp >= 0;)
						if(strcmp(*unTableauChaine_element(g_ensemble->derniers, comp), chemin) == 0)
							break;
					if(comp < 0)
						if(traiter(chemin, date, suiteDest, tailleSuiteDest, g_ensemble) != 0) ERR(ePendant);
					break;
				}
				etat = APRES;
			case APRES:
ap:				if(traiter(chemin, date, suiteDest, tailleSuiteDest, g_ensemble) != 0) ERR(ePendant);
				break;
	}
	
	traiter(NULL, NULL, suiteDest, tailleSuiteDest, g_ensemble); // En cas de traitement par paquets: on scelle le dernier paquet et on l'expédie.
	
	EB(ePendant)
	
	/* Enregistrement du point où on en est */
	
	if(g_destination) ecrirePrefsEnsemble(g_ensemble);
	
	/* Terminé */
	
	EB(eAlloc)
	EB(eRien)
	EB(ePasAssezGrand)
	EB(eRecherche)
	EB(eMemDateDernier)
	EB(eCd)
	EB(eLecture)
	unEnsemble_detruire(g_ensemble);
	EB(eEnsemble)
	
	return 0;
}
