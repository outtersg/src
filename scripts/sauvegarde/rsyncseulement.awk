#!/usr/bin/awk -f
# Copyright (c) 2018 Guillaume Outters
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Transforme une liste
#   + /d0/d1/fichier
# en
#   + /d0
#   + /d0/d1
#   + /d0/d1/fichier
#   - /*/*/*
#   - /*/*
#   - /*
# afin de préparer pour rsync un --exclude-from ne prenant que les fichiers précisés (et leur dossier).

/^\+ \//{
	d = $0;
	# Tous les dossiers au-dessus figurent en + (à moins d être déjà inclus depuis un autre).
	dessus = "";
	while(d ~ /\/.*\//)
	{
		sub(/\/[^\/]*$/, "", d);
		if(deja[d]) break;
		deja[d] = 1;
		dessus = dessus ? d"\n"dessus : d;
	}
	if(dessus)
		print dessus;
	# On fait figurer une expression pour tous les fichiers frères (au même niveau).
	freres = $0;
	gsub(/\/[^\/]+/, "/*", freres);
	if(length(freres) > length(plf)) # On garde seulement la plus longue fratrie.
		plf = freres;
	print;
}
END{
	sub(/^\+/, "-", plf);
	while(plf ~ /[\/]/)
	{
		print plf;
		sub(/\/[^\/]*$/, "", plf);
	}
}
