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
		eval garg_sep=\"\$garg_sep_$garg_var\"
		if [ $garg_mode = ajoute ] ; then
			garg_sep0="$garg_sep"
			garg_sep="`IFS="$garg_sep" ; sep $garg_contenu "$@"`"
			export garg_sep_$garg_var="$garg_sep"
			# Il est attendu qu'avec IFS=, une , en fin délimite une fin de paramètre. Ainsi ",," comprend deux paramètres vides, "," un seul paramètre vide, "" aucun paramètre. Ceci est explicitement dit dans la man page de sh sous FreeBSD 11, et pas clair dans la man page de bash, mais en tout cas son implémentation suit.
			export $garg_var="`IFS="$garg_sep0" ; for param in $garg_contenu "$@" ; do printf "%s%s" "$param" "$garg_sep" ; done`"
		else
			IFS="$garg_sep"
			garg -l "$@" $garg_contenu
		fi
	fi
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
		sh -c 'f() { echo $# ; for i in "$@" ; do echo "== $i" ; done ; } ; IFS="$garg_sep_garg_testParams" ; f "au début" $garg_testParams' > /tmp/temp.$$.garg_test.2
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
