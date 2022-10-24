# Copyright (c) 2022 Guillaume Outters
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

# À FAIRE: gérer les commentaires /* */ multilignes (donc une annotation commence par une * @, sans le /* détecté avant).
# À FAIRE: afficher le NR, pour recoupement avec un script qui irait chercher les function et autres suivant l'annotation.
# À FAIRE: séparateurs spécifiables.
# À FAIRE: liste noire (--sauf)
# À FAIRE: mode CR (les LF sont remplacés par un CR, ce qui permet de tout restituer en mono-ligne et donc de filtrer d'un simple grep).

BEGIN{
	enCours = "";
	sepv = sprintf("\003"); # Séparateur attribut - valeur.
	sepf = sepv; # Séparateur de fin de valeur.
	sepl = "\n"; # Séparateur de fin de ligne.
	mode = 0;
	for(i = 0; ++i < ARGC;)
	{
		j = i;
		# Paramètres à la Windows (/ au lieu de --) car POSIX précise que tout paramètre en - appartient à awk et non au programme.
		if(ARGV[i] == "/ldif")
		{
			sepv = ": "
			sepl = "\n ";
			sepf = "\n";
		}
		else if(ARGV[i] == "/seult")
		{
			mode = 1; # Liste blanche.
			split(ARGV[i + 1], seult0);
			for(k = 0; seult0[++k];)
				seult[seult0[k]] = 1;
			++i;
		}
		else
		{
			print "# Paramètre "ARGV[i]" non reconnu."
			exit(1);
			# Et pour si jamais un jour on décide de ne pas sortir à la ligne du dessus:
			continue;
		}
		# On consomme "nos" paramètres pour éviter qu'en fin de BEGIN awk tente de les lire comme fichiers.
		while(j <= i)
			ARGV[j++] = "";
	}
}
function finir(){
	if(!mode || seult[attr])
		printf "%s%s", enCours, sepf;
	enCours = "";
}
enCours&&/^[ \t]*(--|#|\/\/)   *[^@]/{
	sub(/^[ \t]*(--|#|\/\/) */, "");
	enCours = enCours""sepl""$0;
	next;
}
enCours{ finir(); }
/^[ \t]*(--|#|\/\/) *@[-_a-zA-Z0-9]+ /{
	sub(/^[ \t]*(--|#|\/\/) *@/, "");
	attr = $1;
	sub(/ +/, sepv);
	enCours = $0;
}
END{ if(enCours) finir(); }
