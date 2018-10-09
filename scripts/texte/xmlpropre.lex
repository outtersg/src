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

%}

%%

\<\?xml[^>]*\> { fprintf(yyout, "%s", yytext); }
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
