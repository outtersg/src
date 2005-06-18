%%
\<[^>]*rating=\"[23].0\"[^>]*\> { char * ptr = strstr(yytext, "file=\""); if(ptr) { ptr += 6; char * fin = strstr(ptr, "\""); if(fin) { fwrite(ptr, fin - ptr, 1, yyout); fputc('\n', yyout); } } }
. {}
\n {}
%%
int yywrap() { return 1; }
int main(int argc, char ** argv) { yylex(); }
