#!/bin/sh
# Copyright (c) 2020 Guillaume Outters
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

# Arbre des Processus
# Similaire au ps -faux Linux.
# Utilisation: ap [<filtre>]
#   <filtre>
#     Regex awk: seules les arborescences comportant un processus répondant à ces critères seront affichées.
ap()
{
	LC_ALL=C ps axwwo user,pid,ppid,%cpu,%mem,vsz,rss,tt,stat,start,time,command | awk \
'
function faire(i, ind, numf) {
	if(ls[i])
	{
		aff = ls[i];
		if(((RLENGTH = posCommande) >= 0) || match(aff, /^[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +/))
			aff = substr(aff, 1, RLENGTH)""ind""substr(aff, 1 + RLENGTH);
		print aff;
	}
	if(nfs[i])
	{
		gsub(/├ /, "│ ", ind);
		gsub(/└ /, "  ", ind);
		for(numf = 0; ++numf <= nfs[i];)
			faire(fs[i,numf], ind""(numf == nfs[i] ? "└ " : "├ "));
	}
}
'"`_ap_filtres "$@"`"'
NR==1{ posCommande = match($0, /COMMAND/) - 1; print; next; }
{
	ls[$2] = $0;
	ps[$2] = $3;
	if(match($0, /bin\/init|tmux: server|bin\/systemd/)) ss[$2] = 1; # SourceS
	if($2 != $3)
		fs[$3,++nfs[$3]] = $2;
	else
		fs[$3,0] = $2;
}
END{
	# Les sources (init, etc.) laissent leur fils prendre leur envol (se détacher d eux) tout en gardant un œil sur eux (les gardant comme fils).
	# De cette manière:
	# - si on attaque par le fils (avec un filtre, pour recherche par exemple tous les vim), la source n apparaîtra pas
	# - mais si on attaque par la source (ex.: tmux) on verra bien tous ses fils
	for(s in ss)
		for(numf = nfs[s]; numf-- > 0;)
			ps[fs[s,numf]] = 0;
	if(nTrouves)
		for(numTrouve = 0; ++numTrouve <= nTrouves;)
		{
			for(p = trouves[numTrouve]; ps[p] && ps[p] != p; p = ps[p]) {}
			chapeaux[p] = 1;
		}
	for(p in nfs)
		if(!ps[p] || ps[p] == p)
			if(!nTrouves || chapeaux[p])
			faire(p, "");
}
'
}

_ap_filtres()
{
	local p
	for p in "$@"
	do
		echo "/`echo "$p" | sed -e 's#/#\\/#g'`/{ trouves[++nTrouves] = \$2; }"
	done
}

#- PHP -------------------------------------------------------------------------

compup()
{
	local fournisseur=gui
	
    (
		local d="`pwd`"
		while [ ! -d vendor -o ! -f composer.json ]
		do
			cd ..
			[ "$PWD" != / ] || { echo "# composer.json et vendor introuvables dans $d." >&2 ; return 1 ; }
		done
		
		local vendu="vendor/$fournisseur"
        find "$vendu" -type l -exec rm \{\} \;
        composer update "$@" || return $?
		find "$vendu" -name _darcs | grep -q . && echo "# Trouvé des _darcs dans $PWD/$vendu; c'est louche, je sors." >&2 && return 1
        rm -Rf "$vendu" || return $?
        ln -s "$HOME/src/projets" "$vendu" || return $?
    )
}
