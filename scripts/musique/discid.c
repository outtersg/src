/*
     cc -o discid discid.c `pkg-config libdiscid --cflags --libs`
 * ou:
     cc -o discid discid.c -I/usr/local/include -L/usr/local/lib -ldiscid
 */

#include <stdio.h>
#include <string.h>
#include <discid/discid.h>

#define MODE_ID 0
#define MODE_MUSICBRAINZ 1
#define MODE_FREEDB 2

int main(int argc, char ** argv)
{
	int i;
	char * chemin = NULL;
	int mode = MODE_ID;
	
	for(i = 0; ++i < argc;)
		if(0 == strcmp(argv[i], "-u")) /* u comme url. */
			mode = MODE_MUSICBRAINZ;
		else if(0 == strcmp(argv[i], "-f")) /* u comme FreeDB. */
			mode = MODE_FREEDB;
		else
			chemin = argv[i];
	
	if(!chemin)
	{
		fprintf(stderr, "# Veuillez préciser en paramètre le chemin d'accès au lecteur CD.\n");
		return 1;
	}
	
	DiscId * disque = discid_new();
	if(discid_read_sparse(disque, chemin, 0) == 0)
	{
		fprintf(stderr, "# Erreur: %s\n", discid_get_error_msg(disque));
		return 1;
	}
	
	switch(mode)
	{
		case MODE_ID: printf("%s\n", discid_get_id(disque)); break;
		case MODE_MUSICBRAINZ: printf("%s\n", discid_get_submission_url(disque)); break;
		case MODE_FREEDB: printf("%s\n", discid_get_freedb_id(disque)); break;
	}
	
	discid_free(disque);
}
