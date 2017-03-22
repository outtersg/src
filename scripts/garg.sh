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
	# À FAIRE: s'assurer qu'en cas d'appels récursifs on n'écrase pas nos valeurs. Ou en cas d'appel d'une fonction qui elle-même nous appelle, sur un double for.
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
			":")
				true
				;;
			*)
				garg "$1" garg -a _garg_params
				;;
		esac
		shift
	done
	garg _garg_params
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
		# Dépilage des tests.
		for garg_testNumTest in 1 2 ; do
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
