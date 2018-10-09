%{
/*
 * Copyright (c) 2018 Guillaume Outters
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

#include <string.h>

char g_tabs[] = "																";
int g_niveau;
char g_debutChaine;
char g_aLaLigne = -1; // -1: passage à la ligne autorisé (on laisse passer ceux repérés); 0: passage à la ligne interdit (bloqués); 1: passage à la ligne artificiel à forcer avant le prochain truc à sortir.
#define g_indentation &g_tabs[g_niveau > 0 ? g_niveau : 0]
int g_niveauPar = 0;

char g_monoligner = 0;

#include "diag.flex.c"

void aff()
{
	char * ptr = yytext;
	while(*ptr == '\n' || *ptr == '\t' || *ptr == ' ') ++ptr;
	fprintf(yyout, "\n%s%s", g_indentation, ptr);
}

void brut()
{
	if(g_aLaLigne > 0)
	{
		aff();
		g_aLaLigne = 0;
	}
	else
		fprintf(yyout, "%s", yytext);
}

%}

%x chaine commSimple commEtoile

%%

\/\/ { BEGIN commSimple; brut(); }
<commSimple>\n { BEGIN 0; brut(); g_aLaLigne = -1; }
<commSimple>.+ { brut(); }

\/\* { BEGIN commEtoile; brut(); }
<commEtoile>\*\/[ \t\r\n]* { BEGIN 0; brut(); char * c; for(c = yytext; *c != '\n' && *++c;) {} if(*c) g_aLaLigne = -1; }
<commEtoile>([^*]|\n)+|. { brut(); }

["'] { BEGIN chaine; g_debutChaine = yytext[0]; brut(); }
<chaine>\\. { brut(); }
<chaine>["'] { if(yytext[0] == g_debutChaine) BEGIN 0; brut(); }
<chaine>([^'"\\]|\n)+|. { brut(); }

\( { ++g_niveauPar; brut(); }
\) { --g_niveauPar; brut(); }


[ \t\r\n]*[[{]([ \t]|\n)*[]}] { brut(); }
[ \t\r\n]*[[{] { aff(); --g_niveau; g_aLaLigne = 1; }
[ \t\r\n]*[]}] { ++g_niveau; aff(); g_aLaLigne = -1; }
[ \t\r\n]*, { brut(); if(!g_niveauPar) g_aLaLigne = 1; }
[ \t\r\n]*; { brut(); if(!g_niveauPar) g_aLaLigne = -1; }
(\r*\n)+[ \t]* { if(!g_monoligner || g_aLaLigne) brut(); }
[ \t]+ { if(!g_aLaLigne) brut(); }
[^\[\]{}'\"/,()\r\n]+|. { brut(); }

%%

#undef chaine

int yywrap() { return 1; }
int main(int argc, char ** argv)
{
	char ** arg;
	char * chaine;
	for(arg = argv; *++arg;)
		if(0 == strcmp(*arg, "-l"))
			g_monoligner = 1;
		else if(0 == strncmp(*arg, "-d", 2))
			for(chaine = *arg; *++chaine;)
				if(*chaine == 'd')
					++g_diag;
	g_niveau = strlen(g_tabs);
	yylex();
	return 0;
}
