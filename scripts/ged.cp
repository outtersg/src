#include <stdio.h>

#include <Std/Tableaux.h>

#define DEB if(0) {
#define EB(x) x:
#define FEB }

#define TAILLE 0x4000

/*- Automate -----------------------------------------------------------------*/

class unTraitement
{
	public:
		
		static unTraitement * alloc() throw() { return new(std::nothrow)unTraitement(); }
		unTraitement * init(const char * avecNom) throw() { return init(avecNom, strlen(avecNom)); }
		virtual unTraitement * init(const char * avecNom, int etSaTaille) throw();
		virtual unTraitement * initSansFils(const char * avecNom, int etSaTaille) throw();
		
		unTraitement ** ajouter(unTraitement * fils);
		unTraitement * fils(const char * identifiant);
		
		char * nom;
		unTableau<unTraitement *> * _fils;
		
		int destination; // Numéro du champ dans lequel ira celui-ci.
		
	protected:
		
		unTraitement() throw() {}
};

unTraitement * unTraitement::init(const char * avecNom, int etSaTaille) throw()
{
	if(!initSansFils(avecNom, etSaTaille)) goto e0;
	if(!(_fils = new unTableau<unTraitement *>())) goto e0;
	
	DEB
	EB(e0)	delete nom;
			return NULL;
	FEB
	
	return this;
}

unTraitement * unTraitement::initSansFils(const char * avecNom, int etSaTaille) throw()
{
	if(!this) goto e0;
	if(!(nom = new(std::nothrow) char[etSaTaille+1])) goto e0;
	strncpy(nom, avecNom, etSaTaille);
	nom[etSaTaille] = 0;
	
	destination = -1;
	
	return this;
	
	DEB
	EB(e0)	return NULL;
	FEB
}

unTraitement ** unTraitement::ajouter(unTraitement * fils)
{
	return _fils->ajouter(fils);
}

unTraitement * unTraitement::fils(const char * identifiant)
{
	if(_fils)
		for(int pos = _fils->taille(); --pos >= 0;)
			if(strcmp((*_fils)[pos]->nom, identifiant) == 0)
				return (*_fils)[pos];
	return NULL;
}

/*- Compilation de l'automate ------------------------------------------------*/

unTraitement * ajouter(const char * description, unTraitement * a)
{
	const char * ptr;
	int z, t;
	unTraitement * fils;
	char * temp = new char[strlen(description) + 1];
	
	/* Prélèvement d'un élément de chemin */
	
	for(ptr = description; *ptr && *ptr != '.'; ++ptr) {}
	
	/* Recherche dans les existants */
	
	t = ptr - description;
	
	strncpy(temp, description, t);
	temp[t] = 0;
	if((fils = a->fils(temp)))
		return *ptr ? ajouter(ptr + 1, fils) : a;
	
	/* Création */
	
	fils = unTraitement::alloc();
	if(!(fils = fils->init(description, t))) goto e0;
	if(!a->ajouter(fils)) goto e1;
	
	return fils;
	
	DEB
	EB(e1)	delete fils;
	EB(e0)	return NULL;
	FEB
}

/*- Déclaration des lecteurs -------------------------------------------------*/

class unBloc
{
	public:
		
		unBloc() { ptr = fin = debut; }
		
		char debut[TAILLE];
		char * fin;
		char * ptr; // Entre 'debut' et 'fin'.
};

class unLecteur
{
	public:
		
		virtual void commencer(unLecteur * depuis) = 0;
		virtual unLecteur * lire(unBloc & bloc) = 0;
};

/* Remplit le bloc de données à partir d'un fichier */

class unLecteurRemplisseur : public unLecteur
{
	public:
		
		unLecteurRemplisseur(int fichier);
		
		virtual void commencer(unLecteur * depuis);
		virtual unLecteur * lire(unBloc & bloc);
		
	protected:
		
		int _fichier;
		unLecteur * _courant;
};

/* En début de ligne, se trouve la "profondeur" de l'info qu'elle contient */

class unLecteurProfondeur : public unLecteur
{
	public:
		
		virtual void commencer(unLecteur * depuis);
		virtual unLecteur * lire(unBloc & bloc);
		
		int profondeur() { return _profondeur; }
		
	protected:
		
		int _profondeur;
};

/* Ensuite on trouve l'identifiant permettant de donnée le "chemin" de l'élément */

class unLecteurChemin : public unLecteur
{
	public:
		
		virtual void commencer(unLecteur * depuis);
		virtual unLecteur * lire(unBloc & bloc);
		
		const char * type() { return _type; }
		const char * id() { return _id; }
		
	protected:
		
		char _remplissage; // -1: _type; 0: indéfini; 1: _id
		char _type[5];
		char _id[0x11];
};

/* Enfin les données à prélever */

class unLecteurContenu : public unLecteur
{
	public:
		
		unLecteurContenu(int nombreColonnes);
		
		virtual void commencer(unLecteur * depuis);
		virtual unLecteur * lire(unBloc & bloc);
		void ecrire(FILE * sortie);
		
	protected:
		
		unTableau<unTableau<char> *> _reserve;
		unTableau<char> ** _colonnes;
		int _nColonnes;
		int _colonne;
};

/* Un lecteur pour les lignes de données qui ne nous intéressent pas */

class unLecteurIgnorant : public unLecteur
{
	public:
		
		virtual void commencer(unLecteur * depuis);
		virtual unLecteur * lire(unBloc & bloc);
};

/*- Définition des lecteurs --------------------------------------------------*/

unLecteurRemplisseur * g_remplisseur;
unLecteurProfondeur * g_profondeur;
unLecteurChemin * g_chemin;
unLecteurContenu * g_contenu;
unLecteurIgnorant * g_ignorant;

unTableau<unTraitement *> g_pile;

/*--- unLecteurRemplisseur ---*/

unLecteurRemplisseur::unLecteurRemplisseur(int fichier)
{
	_fichier = fichier;
}

void unLecteurRemplisseur::commencer(unLecteur * depuis)
{
	_courant = depuis;
}

unLecteur * unLecteurRemplisseur::lire(unBloc & bloc)
{
	int diff;
	if((diff = (bloc.fin - bloc.ptr)) > 0) // Si tout n'avait pas été lu, on replace le reste au début.
		memmove(bloc.debut, bloc.ptr, diff);
	bloc.fin = bloc.debut + read(_fichier, bloc.debut + diff, TAILLE - diff);
	if(bloc.fin <= bloc.debut) return NULL;
	bloc.ptr = bloc.debut;
	
	return _courant;
}

/*--- unLecteurProfondeur ---*/

void unLecteurProfondeur::commencer(unLecteur * depuis)
{
	_profondeur = 0;
}

unLecteur * unLecteurProfondeur::lire(unBloc & bloc)
{
	char c;
	while(true)
	{
		if(bloc.ptr >= bloc.fin) return g_remplisseur;
		if((c = *bloc.ptr) == ' ') { ++bloc.ptr; return g_chemin; }
		if(c >= '0' && c <= '9') _profondeur = _profondeur * 10 + (c - '0');
		else { /* À FAIRE: ERREUR */ }
	}
}

/*--- unLecteurChemin ---*/

void unLecteurChemin::commencer(unLecteur * depuis)
{
	bzero(_type, sizeof(_type));
	bzero(_id, sizeof(_id));
	_remplissage = 0;
}

unLecteur * unLecteurChemin::lire(unBloc & bloc)
{
	char * ptr;
	char * ptrInterne;
	int tailleInterne;
	char * ptrInsertion;
	
	for(ptr = bloc.ptr; ptr < bloc.fin && *ptr != '\n' && *ptr != ' '; ++ptr) {}
	if(!_remplissage)
		_remplissage = bloc.ptr[0] == '@' ? 1 : -1;
	ptrInterne = _remplissage == 1 ? _id : _type;
	tailleInterne = (_remplissage == 1 ? sizeof(_id) : sizeof(_type)) - 1;
	for(ptrInsertion = ptrInterne; ptrInsertion < &ptrInterne[tailleInterne] && *ptrInterne != 0; ++ptrInterne) {}
	if(ptr - bloc.ptr > tailleInterne - (ptrInsertion - ptrInterne)) { /* À FAIRE: ERREUR */ }
	memcpy(ptrInsertion, bloc.ptr, ptr - bloc.ptr);
	bloc.ptr = ptr;
	
	if(ptr >= bloc.fin) return g_remplisseur;
	switch(*ptr++)
	{
		case ' ':
			if(!_type[0])
			{
				_remplissage = -1;
				return this;
			}
			/* Pas de break */
		case '\n':
		{
			if(!_type[0]) /* À FAIRE: ERREUR */ {}
			if(g_pile.taille() < g_profondeur->profondeur())  /* À FAIRE: ERREUR */ {}
			g_pile.retirerNDerniers(g_pile.taille() - g_profondeur->profondeur() - 1);
			g_pile.ajouter(g_pile.dernier() ? g_pile.dernier()->fils(_type) : NULL); // S'il s'agit d'un truc qui ne nous intéressait pas, on en mémorise la profondeur mais le traitement associé est NULL.
			return ptr[-1] == ' ' ? g_pile.dernier() ? (unLecteur *)g_contenu : g_ignorant : g_profondeur;
		}
	}
}

/*--- unLecteurContenu ---*/

unLecteurContenu::unLecteurContenu(int nombreColonnes)
{
	_colonnes = new (unTableau<char> *)[_nColonnes = nombreColonnes];
}

void unLecteurContenu::commencer(unLecteur * depuis)
{
	_colonne = g_pile.dernier() ? g_pile.dernier()->destination : -1;
	if(strcmp(g_chemin->type(), "CONT") == 0)
	{
		if(_colonnes[_colonne])
			_colonnes[_colonne]->ajouter('\n');
	}
	else
	{
		if(!_colonnes[_colonne])
		{
			if(_reserve.taille() == 0)
				_reserve.ajouter(new unTableau<char>());
			_colonnes[_colonne] = _reserve.dernier();
			_reserve.retirerNDerniers(1);
		}
	}
}

void unLecteurContenu::ecrire(FILE * sortie)
{
	for(_colonne = 0; _colonne < _nColonnes; ++_colonne)
	{
		if(_colonne > 0)
			fputc(';', sortie);
		if(_colonnes[_colonne])
		{
			fwrite(&(*_colonnes[_colonne])[0], 1, _colonnes[_colonne]->taille(), sortie); /* À FAIRE: convertir les caractères spéciaux (';' et '\n'); */
			_reserve.ajouter(_colonnes[_colonne]); // La colonne revient dans la réserve, puisqu'elle a fini son boulot ici.
			_colonnes[_colonne] = NULL;
		}
	}
}

unLecteur * unLecteurContenu::lire(unBloc & bloc)
{
	char * ptr;
	for(ptr = bloc.ptr; ptr < bloc.fin && *ptr != '\n'; ++ptr) {}
	if(_colonne >= 0 && _colonnes[_colonne])
		_colonnes[_colonne]->ajouter(bloc.ptr, ptr - bloc.ptr);
	
	if((bloc.ptr = ptr) >= bloc.fin)
		return g_remplisseur;
	else
	{
		++bloc.ptr;
		return g_profondeur;
	}
}


/*--- unLecteurIgnorant ---*/

void unLecteurIgnorant::commencer(unLecteur * depuis)
{
}

unLecteur * unLecteurIgnorant::lire(unBloc & bloc)
{
	for(; bloc.ptr < bloc.fin && *bloc.ptr != '\n'; ++bloc.ptr) {}
	if(bloc.ptr >= bloc.fin)
		return g_remplisseur;
	else
	{
		++bloc.ptr;
		return g_profondeur;
	}
}

/*- Exécution ----------------------------------------------------------------*/

int tourner(unTraitement * traitementRacine)
{
	/* Initialisation */
	
	g_pile.ajouter(traitementRacine);
	
	unBloc bloc;
	
	/* Boucle */
	
	unLecteur * courant = g_profondeur;
	unLecteur * nouveau = g_remplisseur;
	FILE * sortie;
	
	while(true)
	{
		nouveau->commencer(courant);
		courant = nouveau;
		nouveau = courant->lire(bloc);
		
		if(courant == g_profondeur && nouveau != g_remplisseur && g_profondeur->profondeur() == 1) // On change d'élément à la racine, il faut pondre le dernier.
			g_contenu->ecrire(stdout);
	}
	
	fclose(sortie);
	
	return 0;
}

/*- Programme principal ------------------------------------------------------*/

const char * g_filtrePersonne[] = { "INDI.@", "INDI.BIRT.DATE", "INDI.DEAT.DATE", NULL };

unTraitement * compiler(const char ** liste) throw()
{
	int nColonnes;
	unTraitement * t = unTraitement::alloc()->init("<racine>");
	if(!t) goto e0;
	
	for(nColonnes = 0; liste[nColonnes]; ++nColonnes)
		if(!ajouter(liste[nColonnes], t))
			goto e1;
	
	g_remplisseur = new unLecteurRemplisseur(0);
	g_profondeur = new unLecteurProfondeur();
	g_chemin = new unLecteurChemin();
	g_contenu = new unLecteurContenu(nColonnes);
	g_ignorant = new unLecteurIgnorant();
	
	return t;
	
	DEB
	EB(e1)	delete t;
	EB(e0)	return NULL;
	FEB
}

int main(int argc, char ** argv)
{
	if(argc != 1)
	{
		fprintf(stderr, "# Ged\n");
		fprintf(stderr, "# Éclatement de fichiers GEDCOM en CSV\n");
		fprintf(stderr, "# © Guillaume Outters 2003\n");
		fprintf(stderr, "\n");
		fprintf(stderr, "Utilisation: %s\n", argv[0]);
		fprintf(stderr, "\n");
		fprintf(stderr, "Pour chaque type de données, un fichier est créé en ajoutant à <sortie> un\n");
		fprintf(stderr, "suffixe.\n");
		
		return(1);
	}
	
	tourner(compiler(g_filtrePersonne));
	
	return(0);
}