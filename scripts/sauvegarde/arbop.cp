/*
 * Copyright (c) 2003 Guillaume Outters
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

#include <stdio.h>

#include "Chemin/ParcoursArborescence.h"
#include "Erreur/Erreur.h"
#include "Erreur/ErreurNomFichier.h"
#include "Erreur/ErreurSysteme.h"

#pragma mark
/*- Classes ------------------------------------------------------------------*/

#define NON ((unElementArborescence *)-1)
#define ERR ((unElementArborescence *)0)

#define DEB if(0) {
#define EB(x) x:
#define FEB }

#pragma mark
/*- Classes ------------------------------------------------------------------*/

class unElementArbop : public unElementArborescence
{
	public:
		
		unElementArborescence * initEnPrenantLeNom(unElementArborescence * depuis, const char * avecNom) throw() {  unElementArborescence * retour; if((retour = unElementArborescence::initEnPrenantLeNom(depuis, avecNom)) && depuis) _infos |= depuis->_infos & kASupprimer; return retour; }
		
		void explorer() throw();
		
		enum { kASupprimer = kInfoMax };
		
	public:
		
		friend class unParcoursArbop;
};

void unElementArbop::explorer() throw()
{
	int i, n;
	if((n = _suivants.taille()) > 0)
		for(i = 0; i < n; ++i)
			static_cast<unElementArbop *>(_suivants[i])->explorer();
	else if(!(_infos & kASupprimer))
		fprintf(stdout, "%s\n", cheminTemp());
}

class unParcoursArbop : public unParcoursArborescence
{
	public:
		
		virtual unParcoursArborescence * init() throw() { unParcoursArborescence * retour; if((retour = unParcoursArborescence::init())) _enCours = false; return retour; }
		
		int traiter(const char * chemin, bool ajoutSinonRetrait) throw();
		virtual unElementArborescence * trouver(const char * elementDeChemin) throw();
		
		void explorer() throw();
		
	protected:
		
		virtual unElementArborescence * creer(unElementArborescence * parent, const char * nom, bool dossier) throw() { return new unElementArbop(); }
		
		bool _enCours; // true: ajout/suppression de répertoires, sinon fonctionnement d'unParcoursArborescence
};

void unParcoursArbop::explorer() throw()
{
	static_cast<unElementArbop *>(_racine)->explorer();
}

int unParcoursArbop::traiter(const char * chemin, bool ajoutSinonRetrait) throw()
{
	unElementArborescence * retour;
	
	_enCours = true;
	
	if(marquerCourant(courant()) == 0) { _enCours = false; return 0; }
	if((retour = unParcoursArborescence::allerAuBoutDe(chemin)))
		if(!ajoutSinonRetrait)
			retour->_infos |= unElementArbop::kASupprimer;
		else
			retour->_infos &= -1-unElementArbop::kASupprimer;
	revenir();
	
	_enCours = false;
	
	return (int)retour;
}

unElementArborescence * unParcoursArbop::trouver(const char * elementDeChemin) throw()
{
	if(!_enCours) return unParcoursArborescence::trouver(elementDeChemin);
	
	unElementArborescence * retour;
	
	if((retour = courant()->chercher(elementDeChemin)) != NON) return retour;
	
	refleter();
	
	if((retour = courant()->chercher(elementDeChemin)) == NON) { g_erreurs << new uneErreurNomFichier(elementDeChemin) << new uneErreurSysteme(ENOENT); return ERR; }
	
	return retour;
}

#pragma mark
/*- Variables globales -------------------------------------------------------*/

unElementArborescence * g_racine;

#pragma mark
/*- Mode d'emploi ------------------------------------------------------------*/

void utilisation()
{
	fprintf(stderr, "#  Arbop\n");
	fprintf(stderr, "#  Additions et soustractions sur arborescences\n");
	fprintf(stderr, "#  © Guillaume Outters 2003\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Utilisation: arbop <chemin de départ> ( [+|-] (<chemin>)* )*\n");
	fprintf(stderr, "Si la première opération est une soustraction ou si aucune opération n'est\n");
	fprintf(stderr, "effectuée, le contenu du chemin de départ est inclus par défaut.\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "ATTENTION: tester avant d'inclure dans un script. arbop est bogué jusqu'à la\n");
	fprintf(stderr, "           moëlle, surtout sur les '..'.\n");
}

#pragma mark
/*- Point d'entrée -----------------------------------------------------------*/

int main(int argc, char ** argv)
{
	unParcoursArbop * parcours;
	bool oui;
	
	if(argc < 2 || (argc >= 3 && ((argv[2][0] != '+' && argv[2][0] != '-') || argv[2][1]))) { utilisation(); exit(1); }
	
	if(!(parcours = static_cast<unParcoursArbop *>((new unParcoursArbop())->init()))) goto e0;
	if(!(g_racine = parcours->allerAuBoutDe(argv[1]))) goto e1;
	
	if(argc >= 3 && !strcmp(argv[2], "+"))
		g_racine->_infos |= unElementArbop::kASupprimer;
	
	for(argv += 2, argc -= 2; argc > 0; --argc, ++argv)
	{
		if( ((*argv)[0] == '+' || (*argv)[0] == '-') && !(*argv)[1] )
			oui = ((*argv)[0] == '+');
		else
			if(!parcours->traiter(*argv, oui)) goto e1;
	}
	
	if(g_erreurs.nombre()) goto e1; // On ne tolère aucune erreur
	
	DEB
	EB(e1)	parcours->boum();
	EB(e0)	g_erreurs.afficher();
			return(1);
	FEB
	
	parcours->explorer();
	
	parcours->boum();
	return(0);
}