#!/bin/sh
# Copyright (c) 2024 Guillaume Outters
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

# Trie son entrée standard en fonction des dépendances qui y sont exprimées.
# Format de l'entrée standard:
#   <clé> <libellé> <clé de préprequis>*
# En l'absence de prérequis, le tri est stable (les premières lignes restent premières).

# À FAIRE: permettre de confondre <clé> et <libellé>

# Exemple d'utilisation:
#   # Avec un sort pour que par défaut les fichiers soient classés par nom.
#   prefixe=…
#   find . -name "$prefixe*.sh" -o -name "$prefixe*.sql" | while read f ; do
#       # On fouille chaque entrants à la recherche de ses prérequis:
#       printf "%s %s %s\n" "`basename "$f"`" "$f" "`egrep '^(#|--)@(après|apres|(pré|pre)req(uis)*) ' < "$f" | cut -d ' ' -f 2- | tr '\012,' ' '`"
#   done | sort | awk -f …/trifouille.awk

BEGIN{
	nt = 0; # Nombre de Tâches.
}
{
	++nt;
	ts[$1] = $2; # Tâches
	trs[$1] = 1; # Tâches réelles; car tester la présence d'une tâche va créer une entrée dans le tableau, on ne veut donc pas polluer les index de ts. trs nous sert à ce test.
	npr[$1] = NF - 2; # Nombre de prérequis par tâche.
	for(i = 2; ++i <= NF;) pr[$1"/"(i - 3)] = $i;
}
function trouer(cle, numpr){
	for(j = numpr; ++j < npr[cle];)
		pr[cle"/"(j - 1)] = pr[cle"/"j];
	delete pr[cle"/"j];
	--npr[cle];
}
END{
	# On signale les prérequis introuvables.
	for(t in ts)
		for(i = -1; ++i < npr[t];)
			if(!trs[pr[t"/"i]])
			{
				print "# "t": prérequis '"pr[t"/"i]"' introuvable ignoré." > "/dev/stderr";
				trouer(t, i);
				--i;
			}
	# Puis on affiche, en commençant par ceux sans prérequis.
	while(nt)
	{
		minnpr = -1;
		pppr = ""; # Plus Petit PréRequéreur (celui qui a le moins de prérequis).
		
		for(t in ts)
		{
			# Si cette tâche a déjà été sortie, on passe.
			if(!trs[t]) continue;
			
			# Si nous sommes le moins prérequérant, on se signale.
			if(minnpr < 0 || npr[t] < minnpr)
			{
				minnpr = npr[t];
				pppr = t;
			}
			
			# Aïe, encore des prérequis toujours pas passés: on ne peut traiter à ce tour-ci.
			if(npr[t]) continue;
			
			print t""FS""ts[t];
			trs[t] = 0;
			# Et on libère tous ceux qui dépendent de nous.
			for(t2 in ts)
				for(i = -1; ++i < npr[t2];)
					if(pr[t2"/"i] == t)
					{
						trouer(t2, i);
						--i;
					}
			--nt;
		}
		
		# Bon si rien n'a avancé ce tour-ci, on fait sauter un prérequis presque au pif.
		
		if(minnpr > 0)
		{
			prr = ""; # PréRequis Restants.
			for(i = -1; ++i < minnpr;)
				prr = (prr ? prr", " : "")pr[pppr"/"i];
			
			print "# Boucle infinie. Pour débloquer les prérequis restants de "pppr" sautent ("prr")." > "/dev/stderr";
			
			npr[pppr] = 0;
		}
	}
}
