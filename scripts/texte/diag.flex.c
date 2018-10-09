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
 
int g_diag = 0;

const char * diag_balises = "[]<>{}";
int diag_nBalises = 0;
const char * diag_couleurs[] =
{
	"1;32",
	"1;31",
	"1;33",
	"1;34",
	"1;36",
	"1;35",
	"1;4;32",
	"1;4;31",
	"1;4;33",
	"1;4;34",
	"1;4;36",
	"1;4;35",
};
int diag_nCouleurs = 0;

void diag_balise(int regle, int fermante);

void diag_init()
{
	if(!diag_nBalises)
	{
		diag_nBalises = strlen(diag_balises) / 2;
		diag_nCouleurs = sizeof(diag_couleurs) / sizeof(diag_couleurs[0]);
		
		if(g_diag >= 2)
		{
			FILE * vraiYyout = yyout;
			yyout = stderr;
			for(int i = 0; ++i < YY_NUM_RULES;)
			{
				diag_balise(i, 0);
				fprintf(yyout, "règle %d", i);
#ifdef FLEX_DEBUG
				fprintf(yyout, " (l. %d)", yy_rule_linenum[i]);
#endif
				diag_balise(i, 1);
				fprintf(yyout, "\n");
			}
			yyout = vraiYyout;
		}
		
		if(g_diag < 3)
			yy_flex_debug = 0;
	}
}

void diag_balise(int regle, int fermante)
{
	diag_init();
	
	int posRegle = regle - 1;
	const char * balise = &diag_balises[2 * ((posRegle / diag_nCouleurs) % diag_nBalises)];
	const char * couleur = diag_couleurs[posRegle % diag_nCouleurs];
	fprintf(yyout, "[%sm%c[0m", couleur, balise[fermante]);
}

void diag_ouvrir(int regle)
{
	if(g_diag)
		diag_balise(regle, 0);
}

void diag_fermer(regle)
{
	if(g_diag)
		diag_balise(regle, 1);
}

#define YY_USER_ACTION diag_ouvrir(yy_act);
#define YY_BREAK diag_fermer(yy_act); break;
