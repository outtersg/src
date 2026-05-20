#!/bin/sh
# Copyright (c) 2020-2022 Guillaume Outters
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

#- Programmation ---------------------------------------------------------------

# Attend une <condition> <n> fois <délai> secondes
# Utilisation:
#   attend [-c <n>] [-w <delai>] <condition>
#   attend [<n> [<delai>]] <condition>
attend()
{
	local n= delai=
	
	while [ $# -gt 0 ]
	do
		case "$1" in
			-c) n="$2" ; shift ;;
			-w) delai="$2" ; shift ;;
			*[^.0-9]*) break ;;
			*)
				{ [ -z "$n" ] && n="$1" ; } || { [ -z "$delai" ] && delai="$1" ; } || break
				;;
		esac
		shift
	done
	while [ $n -gt 0 ]
	do
		"$@" && return || true
		sleep "$delai"
		n=`expr $n - 1`
	done
	"$@"
}

#- Processus -------------------------------------------------------------------

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
	if(match($0, /s?bin\/init|tmux: server|tmux$|foot.*--server|bin\/systemd|bin\/launchd|Terminal\.app|login -pf/)) ss[$2] = 1; # SourceS
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
		for(numf = nfs[s] + 1; --numf >= 0;)
			ps[fs[s,numf]] = 0;
	# Combien avait-on de paramètres? Si on n a rien trouvé mais qu on a cherché alors on n affiche rien.
	if(!nTrouves && '"$#"' > 0)
		exit;
	if(nTrouves)
		for(numTrouve = 0; ++numTrouve <= nTrouves;)
		{
			for(p = trouves[numTrouve]; ps[p] && ps[p] != p; p = ps[p]) {}
			chapeaux[p] = 1;
		}
	for(p in ls)
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
		echo "/`echo "$p" | sed -e 's#/#\\/#g'`/{ if(\$3 != $$) trouves[++nTrouves] = \$2; }"
	done
}

#- XML -------------------------------------------------------------------------

cx()
{
	local f="$1" ; [ -n "$f" ] || f=/tmp/0.xml
	cgi | xmlpropre > "$f" && vi "$f"
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

#- Variables et manipulations --------------------------------------------------

# RÉPArtir les PAramètres.
# Utilisation à l'intérieur d'une fonction (ex. pour faire sauter le second paramètre):
#   montest() { [ $i -ne 2 ] ; } ; repapa montest "$@" ; eval "$repapa"
repapa()
{
	local param= i=0 test="$1" ; shift
	repapa=
	for param in "$@"
	do
		i=$((i+1))
		if $test ; then repapa="$repapa \"\$$i\"" ; fi
	done
	repapa="set --$repapa"
}
repapa0()
{
	local param= i=0 test="$1" ; shift
	repapa=
	for param in "$@"
	do
		case $i in 0) set -- ;; esac
		i=$((i+1))
		if $test ; then set -- "$@" "$param" ; fi
	done
	IFS=\; # À FAIRE: s'assurer un IFS qui ne figure pas dans les paramètres.
	repapa_="$*"
	unset IFS
	repapa='IFS=\; ; set -- $repapa_ ; unset IFS'
}

filtrer()
{
	fichier="$1"
	shift
	"$@" < "$fichier" > /tmp/temp.$$.filtrer && cat /tmp/temp.$$.filtrer > "$fichier"
}

# incruster [-c|-d] <incruste> <dans> <début> <fin>
# incruster [-c|-d] <incruste> <dans> -b <bloc> <pos bloc 1> <pos bloc 2>…
# incruster [-c|-d] <incruste> <dans> -b <bloc> / <n blocs> <largeur totale>
#   -c
#     Justification centrée.
#   -d
#     Justification à droite.
# À FAIRE: -B, où le bloc prend toute la largeur (-b s'arrête 1 avant, pour laisser un séparateur entre les blocs).
	# À FAIRE: savoir que les séquences d'échappement ANSI occupent une place nulle. Et que les accents n'en prennent qu'une?
incruster()
{
	# Pour le formatage (justification centrée), awk se révélera précieux (même si printf permettrait de faire du justifié à droite);
	# et plutôt que de bricoler un assemblage de shell (interprétation des paramètres) et d'awk (travail effectif),
	# partons sur du tout awk, qui sera plus efficace.
	awk '
function err(message){
	print "# "message > "/dev/stderr";
	exit 2;
}
# Division entière arrondie.
function divarr(dividende, diviseur){
	modulo = dividende % diviseur;
	r = (dividende - modulo) / diviseur;
	if(modulo >= diviseur / 2) ++r;
	return r;
}
function serpe(chaine, taille){
	chaine = substr(chaine, 1, taille);
	if(length(chaine) < taille)
	{
		manque = taille - length(chaine);
		chaine = chaine""sprintf("%"manque"."manque"s", "");
	}
	return chaine;
}
BEGIN{
	#- Analyse des paramètres --------------------------------------------------
	
	split("incruste,dans", paramsARemplir, /,/);
	numParamARemplir = 1;
	autoblocs = 0;
	justif = -1;
	for(i = 0; ++i < ARGC;)
	{
		if(ARGV[i] == "-b")
		{
			numBloc = 0 + ARGV[++i];
			if(ARGV[i + 1] == "/")
			{
				nBlocs = 0 + ARGV[i + 2];
				autoblocs = 1;
				i += 2;
			}
			continue;
		}
		if(ARGV[i] == "-c") { justif = 0; continue; }
		if(ARGV[i] == "-d") { justif = 1; continue; }
		if(numParamARemplir <= 2)
		{
			if(paramsARemplir[numParamARemplir] == "incruste")
				incruste = ARGV[i];
			else if(paramsARemplir[numParamARemplir] == "dans")
				dans = ARGV[i];
			++numParamARemplir;
			continue;
		}
		if(numBloc)
			if(autoblocs)
				largeur = 0 + ARGV[i];
			else
			{
				--i;
				posBlocs[nBlocs = 0] = 0;
				while(++i < ARGC)
					posBlocs[++nBlocs] = 0 + ARGV[i];
				largeur = posBlocs[nBlocs];
			}
		else
		{
			debut = 0 + ARGV[i++];
			fin = 0 + ARGV[i++];
		}
	}
	
	if(autoblocs && !largeur)
	{
		"tput cols" | getline largeur;
		--largeur; # Dans un terminal, on ne veut surtout pas occuper la dernière colonne, sinon ça repousse le curseur un caractère après c est-à-dire sur une nouvelle ligne.
	}
	
	#- Traitement --------------------------------------------------------------
	
	if(!debut)
	{
		if(autoblocs)
		{
			debut = divarr(numBloc * largeur, nBlocs);
			fin = divarr((numBloc + 1) * largeur, nBlocs);
		}
		else
		{
			if(numBloc > 0 && !posBlocs[numBloc + 1]) err("numBloc demande à ce que la position du bloc soit définie.");
			debut = posBlocs[numBloc];
			fin = posBlocs[numBloc + 1];
		}
		if(numBloc + 1 < nBlocs) --fin; # On laisse un espace entre deux blocs.
	}
	
	avant = serpe(dans, debut);
	if(justif >= 0 && (tVide = fin - debut - length(incruste)) > 0)
		incruste = serpe("", justif > 0 ? tVide : (tVide - tVide % 2) / 2)""incruste;
	incruste = serpe(incruste, fin - debut);
	apres = substr(dans, fin + 1);
	print avant""incruste""apres;
	exit;
}
' "$@"
}

#- Dates -----------------------------------------------------------------------

# À FAIRE: rapatrier datesend de rcs/shrc

# Détermine si nous sommes un jour donné dans le mois, ou un dernier jour.
# Ex.: pseudojour 01 d -2 # Vrai si nous sommes le 1er, le dernier, ou l'avant-dernier jour du mois (d est synonyme de -1).
# /!\ -1 signifie "1 jour avant le 1er", soit le dernier du mois; l'arithmétique voudrait que cette veille du 1er soit le 0 (plutôt que le -1), mais les usages sont ce qu'ils sont.
pseudojour()
{
	local jour=`date +%d`
	local t jplus28= maintenant demain
	
	for t in "$@"
	do
		# Jour numérique: facile, ça colle ou ça ne colle pas.
		case $jour in
			$t|0$t) return ;;
		esac
		
		# Jour symbolique: on va avoir devoir calculer.
		
		case $t in
			[0-9]*) continue ;; # Ah non là pas symbolique.
			dernier|D|d) t=-1 ;;
		esac
		
		case "$maintenant" in "") maintenant=`date +%s` ;; esac
		case $t in
			# À FAIRE: f, f-1 pour les fériés. Notons que pour f-1 on ne pourra reposer sur jplus28, il faudra un jplus1.
			-[0-9]*)
				case "$jplus28" in "")
					jplus28=$((maintenant+3600*24*28))
					jplus28=`datesend $jplus28 +%d`
					;;
				esac
				case $((28-jplus28+t)) in -1) return ;; esac
				;;
		esac
	done
	false
}

#- Réseau ----------------------------------------------------------------------

# curl qui renvoie son code HTTP si différent de 2xx.
curly()
{
	local r t=/tmp/temp.curly.$$.stderr
	
	curl -v -L "$@" 2> $t || { r=$? ; rm -f $t ; return $r ; }
	
	r="`awk '/< HTTP\//{r=$3}END{print r}' < $t`"
	HTTP_STATUS=$r
	case "$r" in 2??) r=0 ;; esac
	
	rm -f $t
	return $r
}

#- Édition ---------------------------------------------------------------------

vi()
{
	local p t=vi
	for p in "$@"
	do
		t="$t `basename "$p"`"
		done
	titrer "$t"
	vim -X "$@"
	titrer
}

#- Terminal --------------------------------------------------------------------

# ls images
li()
{
	local f
	# À FAIRE: dans tmux, une séance d'échappement supplémentaire?
	for f in "$@"
	do
		echo "$f"
		magick "$f" -geometry 256 sixel:-
	done
}

titrer()
{
	case "$TMUX_PANE" in
		"")
			case "$1" in "") printf '\033[23;0t' > /dev/tty ; return ;; esac
			printf '\033[22;0t' > /dev/tty # Mémorisation du titre.
			printf %s "]2;$1" > /dev/tty
			;;
		*)
			case "$1" in "") tmux setw automatic-rename ; return ;; esac
			tmux rename-window -t "$TMUX_PANE" "$1"
			;;
	esac
}
