#include <stdio.h>

int main(int argc, char ** argv)
{
	char C[64];
	int i, j;
	char c;
	char transit[4];
	int n, bits;

	/* Initialisation */
	
	i = 0;
	for(c = 'A'; c <= 'Z'; ++c, ++i)
		C[i] = c;
	for(c = 'a'; c <= 'z'; ++c, ++i)
		C[i] = c;
	for(c = '0'; c <= '9'; ++c, ++i)
		C[i] = c;
	C[i++] = '+';
	C[i++] = '/';

	/* Traitement */
	
	for(i = 0; (n = fread(&i, 1, 3, stdin)) > 0; i = 0)
	{
		for(j = -1, n *= 8, bits = 26; n > 0; n -= 6, bits -= 6)
			transit[++j] = C[(i >> bits) & 0x3f];
		for(; j < 3;)
			transit[++j] = '=';
		fwrite(&transit[0], 1, 4, stdout);
	}

	return(0);
}
