%x SEQ

%{

#include <string.h>
#include <strings.h>

typedef struct
{
	unsigned char couleur[3];
	char gras;
}
Reglages;

Reglages g_reglages;
Reglages g_reglagesSeq;
Reglages g_reglagesDefaut;

unsigned char ROUGE[3] =  { 0xff, 0x00, 0x00 };
unsigned char VERT[3] =   { 0x00, 0xbf, 0x00 };
unsigned char JAUNE[3] =  { 0xdf, 0xdf, 0x00 };
unsigned char BLEU[3] =   { 0x00, 0x00, 0xff };
unsigned char VIOLET[3] = { 0xbf, 0x00, 0xbf };
unsigned char CYAN[3] =   { 0x00, 0xbf, 0xbf };
unsigned char GRIS[3] =   { 0x7f, 0x7f, 0x7f };
unsigned char ROSE[3] =   { 0xff, 0x00, 0xff };

void RInit(Reglages * ptrR)
{
	bzero(ptrR, sizeof(Reglages));
}

void appliquerSeq()
{
	if(0 == memcmp(&g_reglages, &g_reglagesSeq, sizeof(Reglages)))
		return;
	
	if(0 != memcmp(&g_reglages, &g_reglagesDefaut, sizeof(Reglages)))
		fprintf(yyout, "</span>");
	
	memcpy(&g_reglages, &g_reglagesSeq, sizeof(Reglages));
	if(0 == memcmp(&g_reglages, &g_reglagesDefaut, sizeof(Reglages)))
		return;
	
	fprintf(yyout, "<span style=\"");
	if(g_reglages.couleur[0] || g_reglages.couleur[1] || g_reglages.couleur[2])
		fprintf(yyout, "color:#%02.2X%02.2X%02.2X;", g_reglages.couleur[0], g_reglages.couleur[1], g_reglages.couleur[2]);
	fprintf(yyout, "\">");
}

%}

%%

\[m { RInit(&g_reglagesSeq); appliquerSeq(); }
\[ { memcpy(&g_reglagesSeq, &g_reglages, sizeof(Reglages)); BEGIN(SEQ); }
\n { fprintf(yyout, "<br/>\n"); }

<SEQ>0 { RInit(&g_reglagesSeq); }
<SEQ>31 { memcpy(g_reglagesSeq.couleur, ROUGE, sizeof(g_reglagesSeq.couleur)); }
<SEQ>32 { memcpy(g_reglagesSeq.couleur, VERT, sizeof(g_reglagesSeq.couleur)); }
<SEQ>33 { memcpy(g_reglagesSeq.couleur, JAUNE, sizeof(g_reglagesSeq.couleur)); }
<SEQ>34 { memcpy(g_reglagesSeq.couleur, BLEU, sizeof(g_reglagesSeq.couleur)); }
<SEQ>35 { memcpy(g_reglagesSeq.couleur, VIOLET, sizeof(g_reglagesSeq.couleur)); }
<SEQ>36 { memcpy(g_reglagesSeq.couleur, CYAN, sizeof(g_reglagesSeq.couleur)); }
<SEQ>90 { memcpy(g_reglagesSeq.couleur, GRIS, sizeof(g_reglagesSeq.couleur)); }
<SEQ>95 { memcpy(g_reglagesSeq.couleur, ROSE, sizeof(g_reglagesSeq.couleur)); }
<SEQ>[0-9]+ { fprintf(stderr, "# Séquence %s inconnue.\n", yytext); }
<SEQ>m { appliquerSeq(); BEGIN(0); }

%%

int yywrap() { return 1; }
int main(int argc, char ** argv)
{
	RInit(&g_reglages);
	RInit(&g_reglagesDefaut);
	yylex();
	return 0;
}
