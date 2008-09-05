%{
#ifdef __APPLE__

#include <CoreServices/CoreServices.h>

void initialiser()
{
	
}

void convertir(const char ** source, size_t * ts, char ** dest, size_t *td)
{
	CFStringRef str;
	CFRange plage;
	CFIndex i;
	
	int m;
	str = CFStringCreateWithBytes(NULL, *source, *ts, kCFStringEncodingUTF8, 0);
	
	plage = CFRangeMake(0, CFStringGetLength(str));
	CFStringGetBytes(str, plage, kCFStringEncodingWindowsLatin1, '.', 0, (UInt8 *)*dest, *td, &i);
	
	CFRelease(str);
	
	*td -= i;
	*dest += i;
	*source += *ts;
	*ts = 0;
}

void terminer()
{
	
}

#else

/* iconv pue, il ne sait pas travailler sur les décompositions canoniques
 * utilisées par Mac OS X pour son nommage de fichiers. */

#include <iconv.h>

iconv_t conv;

void initialiser()
{
	conv = iconv_open("ISO-8859-1", "UTF-8");
}

void convertir(const char ** source, size_t * ts, char ** dest, size_t *td)
{
	iconv(conv, source, ts, dest, td);
}

void terminer()
{
	iconv_close(conv);
}

#endif

char entree[256];
char sortie[256];
size_t te = 0;

int val(char c)
{
	return c <= '9' ? c - '0' : c - 'A' + 10;
}

char car(int val) { return val >= 0xa ? val - 10 + 'A' : (val + '0'); }
%}
%%

href=\"[^\"]*\" {
	const char * source = &yytext[6];
	char * dest = &entree[0];
	char * fin = &yytext[yyleng-1];
	size_t ts, td;
	while(source < fin)
	{
		if(*source == '%')
			*dest++ = val(*++source)*16+val(*++source);
		else
			*dest++ = *source;
		++source;
	}
	source = &entree[0];
	te = dest - &entree[0];
	ts = 256;
	dest = &sortie[0];
	convertir(&source, &te, &dest, &ts);

	fputs("href=\"", yyout);
	for(source = sortie; source < dest; ++source)
		if(*(unsigned char *)source <= 0x20 || *(unsigned char *)source >= 0x80)
			fprintf(yyout, "%%%c%c", car(*(unsigned char *)source / 16), car(*(unsigned char *)source % 16));
		else
			fputc(*source, yyout);
	fputc('"', yyout);
}

%%

int yywrap() { return 1; }

int main(int argc, char ** argv)
{
	initialiser();
	yyin = stdin;
	yylex();
	terminer();
	return 0;
}
