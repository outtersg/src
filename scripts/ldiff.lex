/* © Guillaume Outters 2005. Tous droits réservés. */
/*
 * Copyright (c) 2005 Guillaume Outters
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

%{

int g_mouais = 0;
char g_sep = 0;

%}

%%

^dn:\ .* { g_mouais = 1; fputs(yytext, yyout); }
\n\n { fputs(yytext, yyout); }
\n\  {}
\n { fputc(g_mouais ? '\n' : g_sep, yyout); if(g_mouais) g_mouais = 0; }

%%

int yywrap(void)
{
	return(1);
}

int main(int argc, char ** argv)
{
	if(argc < 2)
	{
		char * nom;
		if((nom = strrchr(argv[0], '/'))) ++nom;
		else nom = argv[0];
		fprintf(stderr, "# %s\n", nom);
		fprintf(stderr, "# Prépare un LDIF à la comparaison\n");
		fprintf(stderr, "# © 2005 Guillaume Outters\n");
		fprintf(stderr, "\n");
		fprintf(stderr, "Utilisation: %s [-t] blablaglubroknprthuiduirtarghountaxduv\n", nom);
		fprintf(stderr, "  -t: utiliser des tabulations plutôt que le caractère nul.\n");
		fprintf(stderr, "La commande prend en entrée standard un LDIF, et concatène les attributs des\n");
		fprintf(stderr, "entrées en les séparant par des caractères nuls. Le but final étant:\n");
		fprintf(stderr, "[…] | %s | while read ligne ; do echo \"$ligne\" | tr '\\000' '\\012' | sort ; done\n", nom);
		fprintf(stderr, "on obtient ainsi un LDIF dans lequel les attributs de chaque entrée sont triés,\n");
		fprintf(stderr, "permettant alors de comparer deux LDIF.\n");
		exit(1);
	}
	
	if(strcmp(argv[1], "-t") == 0) g_sep = '\t';
	yylex();
	return(0);
}
