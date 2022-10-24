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
# À FAIRE: liste blanche ou liste noire.
# À FAIRE: mode LDAP (les multi-lignes sont restitués sous forme d'une ligne supplémentaire avec espace initial)
# À FAIRE: mode CR (les LF sont remplacés par un CR, ce qui permet de tout restituer en mono-ligne et donc de filtrer d'un simple grep).

BEGIN{
	enCours = "";
	sep = sprintf("\003");
}
function finir(){
	printf "%s%s", enCours, sep;
	enCours = "";
}
enCours&&/^[ \t]*(--|#|\/\/)   *[^@]/{
	sub(/^[ \t]*(--|#|\/\/) */, "");
	enCours = enCours"\n"$0;
	next;
}
enCours{ finir(); }
/^[ \t]*(--|#|\/\/) *@[-_a-zA-Z0-9]+ /{
	sub(/^[ \t]*(--|#|\/\/) *@/, "");
	sub(/ +/, sep);
	enCours = $0;
}
END{ if(enCours) finir(); }
