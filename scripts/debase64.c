#include <stdio.h>

int main(int argc, char ** argv)
{
	char C[256];
	int pos, val;
	int decalage, bits;
	signed char c;

	/* Initialisation */
	
	for(pos = 256; --pos >= 0;)
		C[pos] = -1;
	pos = 0;
	for(c = 'A'; c <= 'Z'; ++c, ++pos)
		C[c] = pos;
	for(c = 'a'; c <= 'z'; ++c, ++pos)
		C[c] = pos;
	for(c = '0'; c <= '9'; ++c, ++pos)
		C[c] = pos;
	C['+'] = pos++;
	C['/'] = pos++;

	/* Traitement */

	val = 0;
	decalage = 26;
	while(fread(&c, 1, 1, stdin) > 0)
	{
		if((c = C[(unsigned char)c]) >= 0)
		{
			val |= c << decalage;
			if((decalage -= 6) < 0)
			{
				fwrite(&val, 1, bits = (26 - decalage) / 8, stdout); /* On écrit tous les octets complets */
				val <<= (bits *= 8);
				decalage += bits;
			}
		}
	}
	
	if(decalage <= 18) /* Si nous avons au moins un octet de "plein" */
		fwrite(&val, 1, bits = (26 - decalage) / 8, stdout);

	return(0);
}
