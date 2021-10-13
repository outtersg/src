/*
 * Copyright (c) 2013,2015-2017,2021 Guillaume Outters
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

/* CGI: le Chat au Grand Intestin
 * cat capable de bouffer des lignes sans limite de taille.
 *
 * cat > /tmp/xxx refuse les lignes de plus d'un certain nombre de caractères (en ce moment: 1920 caractères)
 * Une fois la limite atteinte, il refuse tout nouveau caractère; on ne peut même pas mettre un retour à la ligne pour mettre la suite sur une nouvelle ligne, il faut effacer le dernier et passer à la ligne.
 * Ce sous bash 5, sh, que l'on appelle un cat, un xmlpropre, un tee /tmp/1 > /dev/null, un php -r 'file_put_contents("/tmp/1", file_get_contents("/dev/stdin"));'.
 * Par contre echo "<2000 caractères>" passe bien.
 * Ce n'est pas lié au copier-coller, car un vi /tmp/1 permet d'y coller le contenu entier.
 * Cela s'avère lié au terminal, bien qu'aucune limite ne semble proche de ces 1920 caractères.
 * Aucune limite ne semble proche de ces 1920 caractères, ni même en comptant l'environnement (https://serverfault.com/a/163390/868098), on arrive alors à 2973 caractère
s (3000?).
 * Par contre read -e y arrive (https://stackoverflow.com/a/51274694/1346819)
 * Voir le mode canonique (https://unix.stackexchange.com/a/643783/452410), mais alors on perd le ^D pour terminer (https://unix.stackexchange.com/a/131221/452410).
 */

#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <termios.h>

#define TAILLE 0x1000

int main(int argc, char ** argv)
{
	struct termios trucs;
	tcflag_t mem;

	if(tcgetattr(0, &trucs) < 0) { fprintf(stderr, "# tcgetattr: %s\n", strerror(errno)); return 1; }
	mem = trucs.c_lflag;
	trucs.c_lflag &= -1-ICANON; /* Ou alors on pourrait jouer sur MAX_CANON. */
	if(tcsetattr(0, TCSANOW, &trucs) < 0) { fprintf(stderr, "# tcsetattr: %s\n", strerror(errno)); return 1; }
	char tampon[TAILLE];
	int n;
	while((n = read(0, &tampon[0], TAILLE)) > 0)
	{
		if(n == 1 && tampon[0] == '')
			break;
		write(1, tampon, n);
	}
	trucs.c_lflag = mem;
	if(tcsetattr(0, TCSANOW, &trucs) < 0) { fprintf(stderr, "# tcsetattr: %s\n", strerror(errno)); return 1; }
	return 0;
}
