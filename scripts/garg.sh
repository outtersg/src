#!/bin/sh

# Renvoie un séparateur qui ne figure dans aucun des paramètres.
sep()
{
	sep_collage="`for arg in "$@" ; do printf "%s" "$arg" ; done`"
	for sep_sep in '|' ':' ';' '@' '#' '!' '+' '=' '\r' ; do
		sep_sep="`printf "$sep_sep"`"
		case "$sep_collage" in
			*"$sep_sep"*) true ;;
			*) printf "%s" "$sep_sep" ; return ;;
		esac
	done
	echo "# Impossible de trouver un séparateur pour \"$sep_collage\"." >&2
	return 1
}

# Règle $garg_sep à la valeur du dernier caractère de $1, à défaut la chaîne vide.
garg_sep_dernier()
{
	# Il est plus rapide de parcourir les valeurs possibles par des fonctions internes, que de forker. On tente d'abord cette solution.
	for garg_sep in '|' ':' ';' '@' '#' '!' '+' '=' "`printf '\r'`"
	do
		case "$1" in
			*"$garg_sep") return 0 ;;
		esac
	done
	if [ -z "$1" ]
	then
		garg_sep=""
		return 0
	fi
	garg_sep="`printf '%s' "$1" | rev`"
	garg_sep="`printf '%c' "$garg_sep"`"
}

# Prépare un IFS pour entreposer des paramètres de façon non destructive.
# Utilisation:
#   mesParams=
#   garg -a mesParams "param 1" "param 2"
#   garg -a mesParams "param 3"
#   garg mesParams echo
garg()
{
	case "$1" in
		-a) garg_mode=ajoute ; shift ;;
		-l) garg_mode=sous ; shift ;;
		*) garg_mode=lance ;;
	esac
	if [ $garg_mode = sous ] ; then
		unset IFS
		"$@"
	elif [ $garg_mode = lance -o $# -gt 0 ] ; then
		garg_var="$1"
		shift
		eval garg_contenu=\"\$$garg_var\"
		garg_sep_dernier "$garg_contenu"
		if [ $garg_mode = ajoute ] ; then
			garg_sep0="$garg_sep"
			garg_sep="`IFS="$garg_sep" ; sep $garg_contenu "$@"`"
			# Il est attendu qu'avec IFS=, une , en fin délimite une fin de paramètre. Ainsi ",," comprend deux paramètres vides, "," un seul paramètre vide, "" aucun paramètre. Ceci est explicitement dit dans la man page de sh sous FreeBSD 11, et pas clair dans la man page de bash, mais en tout cas son implémentation suit.
			export $garg_var="`IFS="$garg_sep0" ; for param in $garg_contenu "$@" ; do printf "%s%s" "$param" "$garg_sep" ; done`"
		else
			IFS="$garg_sep"
			garg -l "$@" $garg_contenu
		fi
	fi
}

# garg interne
# Prend en paramètre ce genre de chose:
# _garg -3 "param libre" "param libre" "param libre" nomVarGarg nomVarGarg : nomVarGargSurLaquelleBoucler nomVarGarg
_garg()
{
	# Première passe: pour repérer l'éventuelle première boucle. Si présente, il nous faut mémoriser la version source des paramères, plutôt que la version résolue (en effet dans le corps de boucle un paramètre peut changer, donc il ne faut surtout pas le résoudre dès à présent).
	
	if _garg_bouclage_necessaire "$@"
	then
		_garg_boucler "$@"
		return
	fi
	
	_garg_params=
	while [ $# -gt 0 ]
	do
		case "$1" in
			-[0-9]*)
				_garg_n="`echo "$1" | cut -c 2-`"
				while [ $_garg_n -gt 0 ]
				do
					shift
					garg -a _garg_params "$1"
					_garg_n="`expr $_garg_n - 1`"
				done
				;;
			*)
				garg "$1" garg -a _garg_params
				;;
		esac
		shift
	done
	garg _garg_params
}

_garg_bouclage_necessaire()
{
	while [ $# -gt 0 ]
	do
		case "$1" in
			-[0-9]*)
				_garg_n="`echo "$1" | cut -c 2-`"
				while [ $_garg_n -gt 0 ]
				do
					shift
					_garg_n="`expr $_garg_n - 1`"
				done
				;;
			":")
				return 0
				;;
		esac
		shift
	done
	return 1
}

# Principe de tous les appels qui suivent:
# - à partir du moment où l'on rentre dans une sous-procédure, nos variables locales ne sont plus garanties, exceptées les arguments $1, etc.
# - on ne peut donc utiliser de variable locale (avec garantie de non-écrasement) que jusqu'à l'appel d'une sous-fonction.
# - dans une boucle for, le premier tour de boucle avec appel de sous-fonction est susceptible de changer les variables locales.
# - on ne peut donc utiliser de variable locale que jusqu'au premier for (et non pas jusqu'au premier appel de sous-fonction dans le corps de ce for).
# Donc, si l'on veut utiliser des variables locales dans une boucle for, le mieux est de les passer à une sous-fonction "juste pour ça" dans laquelle elles seront accessibles, et garanties stables, sous forme d'argument.

_garg_boucler()
{
	_garg_params=
	while [ $# -gt 0 ]
	do
		case "$1" in
			-[0-9]*)
				garg -a _garg_params "$1"
				_garg_n="`echo "$1" | cut -c 2-`"
				while [ $_garg_n -gt 0 ]
				do
					shift
					garg -a _garg_params "$1"
					_garg_n="`expr $_garg_n - 1`"
				done
				;;
			":")
				# On ne traite que cette occurrence, et on appellera une sous-instance de _garg pour traiter tout le reste; nous sortons immédiatement après. Ainsi, si la sous-instance nous charcute nos variables, ce n'est pas un problème. Toute variable utilisée par le lanceur de sous-instance est passée par argument, car les argumets sont les seules variables garanties de rester inchangées (par une sous-fonction) pour la fonction appelée.
				shift
				eval '_garg_a_boucler="$'$1'"'
				shift
				garg_sep_dernier "$_garg_params"
				_garg_sousboucler "$_garg_a_boucler" "$garg_sep" "$_garg_params" "$@"
				return
				;;
			*)
				garg -a _garg_params "$1"
				;;
		esac
		shift
	done
	garg _garg_params
}

# _garg_sousboucler <à boucler gargué> <sép prélude> <prélude gargué> <reste>*
_garg_sousboucler()
{
	_garg_sb_a_boucler="$1" ; shift
	garg_sep_dernier "$_garg_sb_a_boucler"
	IFS="$garg_sep"
	for _garg_tour in $_garg_sb_a_boucler
	do
		_garg_sousfaire "$_garg_tour" "$@"
	done
	unset IFS
}

_garg_sousfaire()
{
	_garg_sf_tour="$1" ; shift
	IFS="$1" ; shift
	_garg_sf_prelude="$1" ; shift
	#shift 3 # On sert d'homme de main à _garg_sousboucler: il nous transmet ses paramètres tels quels, et c'est à nous de faire le ménage (virer les trois premiers qu'il a déjà utilisés): en effet il ne pouvait lui-même faire des "toto=$1 ; shift", car, contenant une boucle for susceptible d'appeler par récursion un autre _garg_sousboucler, les toto risquaient d'être écrasés.
	_garg $_garg_sf_prelude -1 "$_garg_sf_tour" "$@"
}

garg_test()
{
	# Test principal.
	if [ -z "$1" ] ; then
		echo 4 > /tmp/temp.$$.garg_test.0
		echo "== au début" >> /tmp/temp.$$.garg_test.0
		garg_testParams=
		for garg_testParam in facile "avec espace" "`printf "a\nb"`" ; do
			echo "== $garg_testParam" >> /tmp/temp.$$.garg_test.0
			garg -a garg_testParams "$garg_testParam"
		done
		# Test dans le même shell.
		garg garg_testParams garg_test "au début" > /tmp/temp.$$.garg_test.1
		# Test par sh -c, en espérant que le shell courant a transmis les variables au sh lancé.
		garg_sep_dernier "$garg_testParams"
		export garg_sep
		sh -c 'f() { echo $# ; for i in "$@" ; do echo "== $i" ; done ; } ; IFS="$garg_sep" ; f "au début" $garg_testParams' > /tmp/temp.$$.garg_test.2
		# Test par _garg.
		_garg -2 garg_test "au début" garg_testParams > /tmp/temp.$$.garg_test.3
		# Dépilage des tests.
		for garg_testNumTest in 1 2 3 ; do
			diff -uw /tmp/temp.$$.garg_test.0 /tmp/temp.$$.garg_test.$garg_testNumTest && echo "C'est tout bon"\! >&2 || echo "# Différence inattendue." >&2
		done
		rm -f /tmp/temp.$$.garg_test.*
	# Restitution.
	else
		echo $#
		for garg_testParam in "$@" ; do
			echo "== $garg_testParam"
		done
	fi
}
