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
/*
cc -o ~/bin/reve reveil.c -framework IOKit -framework CoreFoundation
*/

#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

#define DEB if(0) {
#define EB(x) x:
#define FEB }

char * nomDe(char ** argv)
{
	char * r;
	if((r = strrchr(argv[0], '/'))) return(++r); else return(argv[0]);
}

void auSecours(char ** argv)
{
	char * nom;
	nom = nomDe(argv);
	fprintf(stderr, "# %s\n", nom);
	fprintf(stderr, "# Réveil en douceur\n");
	fprintf(stderr, "# © 2005 Guillaume Outters\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "Utilisation: %s [[[[AAAA]MM]JJ]hh]mm\n", nom);
}

int valeur(char * chaine, int taille)
{
	int r = 0;
	for(; --taille >= 0; ++chaine)
		if(*chaine >= '0' && *chaine <= '9')
			r = r * 10 + (*chaine - '0');
		else
			return -1;
	return r;
}

int programmerReveil(char * chaine, int contientLesSecondes)
{
	IOReturn r;
	CFGregorianDate joursmoischoses;
	char * ptr;
	CFAbsoluteTime temps;
	CFDateRef date;
	CFTimeZoneRef zone;
	
	/* Lecture de la date */
	
	temps = CFAbsoluteTimeGetCurrent();
	if(!(zone = CFTimeZoneCopyDefault())) { fprintf(stderr, "# Impossible de récupérer la zone.\n"); goto eZone; }
	joursmoischoses = CFAbsoluteTimeGetGregorianDate(temps, zone);
	ptr = &chaine[strlen(chaine)];
	if(contientLesSecondes && ptr >= chaine + 2) joursmoischoses.second = valeur(ptr -= 2, 2); else joursmoischoses.second = 0;
	if(ptr >= chaine + 2) joursmoischoses.minute = valeur(ptr -= 2, 2);
	if(ptr >= chaine + 2) joursmoischoses.hour = valeur(ptr -= 2, 2);
	if(ptr >= chaine + 2) joursmoischoses.day = valeur(ptr -= 2, 2);
	if(ptr >= chaine + 2) joursmoischoses.month = valeur(ptr -= 2, 2);
	if(ptr >= chaine + 4) joursmoischoses.year = valeur(ptr -= 4, 4);
	temps = CFGregorianDateGetAbsoluteTime(joursmoischoses, zone);
	
	/* Programmation */
	
	if(!(date = CFDateCreate(NULL, temps))) { fprintf(stderr, "# Création de la date impossible.\n"); goto eDate; }
	if((r = IOPMSchedulePowerEvent(date, NULL, CFSTR(kIOPMAutoWake))) != 0) if(r == kIOReturnNotPrivileged) fprintf(stderr, "Attention, ce programme doit être lancé en root pour pouvoir sortir l'ordinateur de veille; ne l'y plongez donc pas!\n"); else { fprintf(stderr, "# Impossible de demander le réveil de l'ordi (%x).\n", r); goto eAjouter; }
	
	/* Fini */
	
	CFRelease(date);
	CFRelease(zone);

	return 0;
	
	/* Erreurs (ça arrive) */
	
	DEB
	EB(eAjouter)
		CFRelease(date);
	EB(eDate)
		CFRelease(zone);
	EB(eZone)
		return -1;
	FEB
}

int main(int argc, char ** argv)
{
	if(argc < 1) { auSecours(argv); goto eMalParti; }
	if(programmerReveil(argv[1], 0) != 0) goto eProg;
	return 0;

	DEB
	EB(eProg)
	EB(eMalParti)
		return 1;
	FEB
}
