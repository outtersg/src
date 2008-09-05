%{

/* COPIE: deurl.lex */

char entree[256];

int val(char c)
{
	return c <= '9' ? c - '0' : c - 'A' + 10;
}

char car(int val) { return val >= 0xa ? val - 10 + 'A' : (val + '0'); }
%}
%%

\"\.\.\/\.\.\/[^\"]*/\" { /* Le dernier guillemet est laissé de côté, car il sert pour l'expression suivante. */
	const char * source = &yytext[0];
	char * dest = &entree[0];
	char * fin = &yytext[yyleng];
	while(source < fin)
	{
		if(*source == '%')
			*dest++ = val(*++source)*16+val(*++source);
		else
			*dest++ = *source;
		++source;
	}
	*dest = 0;
	
	fputs(&entree[0], yyout);
}

"\" \"".*\"$ {
	const char * source = &yytext[0];
	char * dest = &entree[0];
	char * fin = &yytext[yyleng-1];
	int n;
	while(*source != '/') *dest++ = *source++;
	 *dest++ = *source++;
	while(source < fin)
	{
		if(*source == '/')
		{
			*dest++ = ':';
			++source;
		}
		else
		{
			if(*source == '"')
				*dest++ = '\\';
			*dest++ = *source++;
		}
	}
	*dest++ = '"';
	*dest = 0;
	
	fputs(&entree[0], yyout);
}

%%

int yywrap() { return 1; }

int main(int argc, char ** argv)
{
	yyin = stdin;
	yylex();
	return 0;
}
