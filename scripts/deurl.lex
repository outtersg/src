%{

/* COPIE: conv.ln.lex */

char entree[256];

int val(char c)
{
	return c <= '9' ? c - '0' : c - 'A' + 10;
}

char car(int val) { return val >= 0xa ? val - 10 + 'A' : (val + '0'); }
%}
%%

\%[0-9A-F][0-9A-F] { fputc(val(yytext[1])<<4|val(yytext[2]), yyout); }

%%

int yywrap() { return 1; }

int main(int argc, char ** argv)
{
	yyin = stdin;
	yylex();
	return 0;
}
