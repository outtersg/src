%{

struct Pile
{
	int taille;
	int _taille;
	char ** pile;
};

void ajouter(struct Pile * pile, char * machin)
{
	if(pile->taille + 1 > pile->_taille)
	{
		int nouvelleTaille = pile->_taille * 2 + 1;
		char ** nouvelle = (char **)malloc(nouvelleTaille * sizeof(char *));
		memcpy(nouvelle, pile->pile, pile->taille * sizeof(char *));
		pile->pile = nouvelle;
		pile->_taille = nouvelleTaille;
	}
	pile->pile[pile->taille++] = machin;
}

char * retirer(struct Pile * pile, int n)
{
	char * r = pile->pile[n];
	if(n < pile->taille) memmove(&pile->pile[n], &pile->pile[n + 1], (pile->taille - n) * sizeof(char *));
	--pile->taille;
	return r;
}

int chercher(struct Pile * pile, char * chaine)
{
	int z;
	for(z = pile->taille; --z >= 0;)
		if(strcmp(pile->pile[z], chaine) == 0)
			return z;
	return -1;
}

char * copie(char * truc)
{
	char * r = (char *)malloc(strlen(truc)+1);
	strcpy(r, truc);
	return r;
}

void diff(char * date, char * moinsDate, char * resultat)
{
	int retenue = 0;
	int groupe;
	int chiffre;
	for(groupe = 3; --groupe >= 0;)
		for(chiffre = 2; --chiffre >= 0;)
		{
			int pos = groupe * 3 + chiffre;
			if((resultat[pos] = '0' + date[pos] - moinsDate[pos] - retenue) < '0')
			{
				resultat[pos] += (chiffre == 0 ? 6 : 10);
				retenue = 1;
			}
			else
				retenue = 0;
		}
}

struct Pile g_pile;
char g_date[9];

void ajouterAvecDerniereDate(char * truc)
{
	ajouter(&g_pile, copie(truc));
	ajouter(&g_pile, copie(g_date));
}

void retirerAvecDerniereDate(char * truc)
{
	int pos;
	if((pos = chercher(&g_pile, truc)) >= 0)
	{
		char * fichier = retirer(&g_pile, pos);
		char * date = retirer(&g_pile, pos);
		
		diff(g_date, date, date);
		if(strcmp(date, "00:00:00") != 0)
			{ fprintf(stdout, "%s %s\n", date, fichier); fflush(stdout); }
		
		free(fichier);
		free(date);
	}
}

%}

%%

\[....\/..\/..\ ..:..:.. { strcpy(g_date, &yytext[12]); }

" opened file "[^=]*/" read=" { ajouterAvecDerniereDate(&yytext[13]); }
" closed file "[^=]*/" (numopen=" { retirerAvecDerniereDate(&yytext[13]); }
.|\n {}

%%

int yywrap() { return 1; }

int main(int argc, char ** argv)
{
	strcpy(g_date, "00:00:00");
	
	yyin = stdin;
	yylex();
	return 0;
}
