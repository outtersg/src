#include <string>
#include <vector>

using std::string;
using std::vector;

#if 0

En-tête fourni par IMP:

"name","email","homeAddress","workAddress","homePhone","workPhone","cellPhone","fax","title","company","notes","lastname"

strings sur Address\ Book.app:

givenname
locality
streetaddress
postofficebox
postaladdress
postalcode
countryname
homepostaladdress
mozillahomelocalityname
mozillahomepostalcode
mozillahomestate
mozillahomecountryname
mail
telephonenumber
homephone
facsimiletelephonenumber
pagerphone
pager
cellphone
mobile
workurl

#endif

class uneLigne : public vector<string>
{
	public:
		
		uneLigne() throw();
		~uneLigne();

		void utiliserCommeEnTete() throw();
		static inline int Premiere() throw();

		const char * champ(const char * nom) throw();
		int utilise(int champ) { return _utilisation ? _utilisation[champ] : 0; }
		
	protected:
		
		static char ** g_colonnes;
		
		int * _utilisation;
};

char ** uneLigne::g_colonnes = NULL;
int uneLigne::Premiere() throw() { return g_colonnes == NULL; }

uneLigne::uneLigne() throw()
{
	int i;

	if(g_colonnes)
	{
		for(i = 0; g_colonnes[i]; ++i) {}
		_utilisation = new int[i];
		while(--i >= 0)
			_utilisation[i] = 0;
	}
}

uneLigne::~uneLigne()
{
	if(_utilisation)
		delete[] _utilisation;
}

void uneLigne::utiliserCommeEnTete() throw()
{
	if(g_colonnes)
	{
		char ** ptrptr;
		for(ptrptr = g_colonnes; *ptrptr; ++ptrptr)
			delete[] ptrptr;
		delete g_colonnes;
	}

	g_colonnes = new (char *)[size() + 1];
	int i;
	const char * ptr;
	g_colonnes[i = size()] = NULL;
	while(--i >= 0)
	{
		ptr = (*this)[i].c_str();
		g_colonnes[i] = new char[strlen(ptr) + 1];
		strcpy(g_colonnes[i], ptr);
	}
}

const char * uneLigne::champ(const char * nom) throw()
{
	for(char ** ptrptr = g_colonnes; *ptrptr; ++ptrptr)
		if(strcmp(nom, *ptrptr) == 0)
		{
			_utilisation[ptrptr - g_colonnes] = 1;
			return (*this)[ptrptr - g_colonnes].c_str();
		}
	return NULL;
}

uneLigne * LireLigne()
{
	if(feof(stdin)) return NULL;

	uneLigne * r = new uneLigne();
	char c;
	int dansGuillemets = 0;
	int despecifie = 0;
	
	r->push_back("");
	string * courant = &(*r)[0];
	while(fread(&c, sizeof(c), 1, stdin) > 0)
	{
		if(despecifie)
		{
			*courant += c;
			despecifie = 0;
		}
		else if(dansGuillemets)
		{
			if(c == '"')
				dansGuillemets = 0;
			else
				*courant += c;
		}
		else switch(c)
		{
			case '"':
				dansGuillemets = 1;
				break;
			case '\n':
				return r;
			case '\\':
				despecifie = 1;
				break;
			case ',':
				r->push_back("");
				courant = &(*r)[r->size() - 1];
				break;
			default:
				*courant += c;
		}
	}
	
	return r;
}

int TraiterLigne(uneLigne & ligne)
{
	if(ligne.Premiere())
		ligne.utiliserCommeEnTete();
	else if(ligne.size() > 1 || ligne[0].size())
	{
		fprintf(stdout, "dn: cn=%s\n", ligne.champ("name"));
		fprintf(stdout, "objectclass: person\n");
		fprintf(stdout, "cn: %s\n", ligne.champ("name"));
		//fprintf(stdout, "sn: %s\n", ligne.champ("lastname"));
		fprintf(stdout, "sn: %s\n", ligne.champ("name"));
		fprintf(stdout, "mail: %s\n", ligne.champ("email"));
		fprintf(stdout, "\n");
		
		int n = ligne.size();
		for(int colonne = 0; colonne < n; ++colonne)
			if(ligne[colonne].size() > 0 && !ligne.utilise(colonne))
				fprintf(stderr, "Champ %d inutilisé: %s\n", colonne, ligne[colonne].c_str());
	}
}

int main(int argc, char ** argv)
{
	uneLigne * ligne;
	while((ligne = LireLigne()))
	{
		TraiterLigne(*ligne);
		delete ligne;
	}
	return 0;
}
