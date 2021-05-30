# Place dans $s un équivalent de realpath de "$@"
rps() { case "/$s/" in */./*|*/../*|*//*) IFS=/ ; _rps $s ;; esac ; }
_rps()
{
	local p p1="$1" sinv=
	for p in "$@"
	do
		sinv="$p/$sinv"
	done
	set -- # Dans $@ on va mettre les .. n'ayant rien trouvé à manger.
	s= # Dans s le résultat.
	for p in $sinv
	do
		case "$p" in
			""|.) true ;;
			..) set -- "$@" "$p" ;;
			*)
				case "$1" in
					"") s="/$p$s" ;;
					*) shift ;;
				esac
				;;
		esac
	done
	[ -z "$*" ] || s="/$*$s"
	if [ -n "$p1" ]
	then
		set -- $s ; shift ; s="$*"
		[ -n "$s" ] || s=.
	elif [ -z "$s" ]
	then
		s=/
	fi
	unset IFS
}
