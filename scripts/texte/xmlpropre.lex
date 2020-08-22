%{

#include <string.h>

char g_tabs[] = "																";
int g_niveau;
#define g_indentation &g_tabs[g_niveau > 0 ? g_niveau : 0]

void aff()
{
	char * ptr = yytext;
	while(*ptr == '\n' || *ptr == '\t') ++ptr;
	fprintf(yyout, "\n%s%s", g_indentation, ptr);
}

/* Affichage initial */
void affin()
{
	char * ptr = yytext;
	char * fin = &yytext[yyleng];
	char cfin;
	/* Les retours à la ligne initiaux sont restitués.
	 * Ils n'étaient initialement pas capturés (ne faisaient pas partie d'yytext), mais alors un <?xml> derrière un retour à la ligne pouvait être pris pour une balise ouvrante (l'expression de cette dernière prenant les \n précédents, or en cas d'intersection lex privilégie l'expression qui a commencé plus tôt).
	 */
	while(*ptr == '\n' || *ptr == '\t')
	{
		if(*ptr == '\n')
			fprintf(yyout, "\n");
		++ptr;
	}
	/* Les retours à la ligne finaux sont supprimés.
	 * En effet notre balise initiale est supposée être suivie d'une balise XML, qui passera par aff() qui se charge des retours à la ligne séparant du prédécesseur (nous).
	 */
	while(--fin >= ptr && (*fin == '\n' || *fin == '\t'));
	cfin = *++fin;
	*fin = 0;
	fprintf(yyout, "%s%s", g_indentation, ptr);
	*fin = cfin;
}

%}

%%

\n*\t*\<\?xml[^>]*\>\n*\t* { affin(); }
\<\!DOCTYPE[^>]*\> { fprintf(yyout, "%s", yytext); }
\n*\t*\<.--([^>]*|[^-]>|[^-]->)*--\> { aff(); }
\n*\t*\<[^/>](\>|[^>]*[^/]\>)[^<]*\<\/[^>]*\> { aff(); }
\n*\t*\<[^>]*\/\> { aff(); }
\n*\t*\<\/ { ++g_niveau; aff(); }
\n*\t*\< { aff(); --g_niveau; }
\<\!\[CDATA\[([^]]*|\][^]]|]][^>])*]]> { aff(); }

%%

int yywrap() { return 1; }
int main(int argc, char ** argv) { g_niveau = strlen(g_tabs); yylex(); return 0; }
