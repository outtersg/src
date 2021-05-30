#!/bin/sh

. rp.sh

t()
{
	local s="$1"
	rps
	if [ "x$s" = "x$2" ]
	then
		printf "  %s -> [32m%s[0m\n" "$1" "$2"
	else
		printf "+ %s -> [36m%s[0m\n- %s -> [31m%s[0m\n" "$1" "$2" "$1" "$s"
	fi
}

t ./coucou coucou
t ./coucou/../../rien ../rien
t /coucou/../a /a
t /coucou/../a/../../OUI /../OUI
t coucou/../a/../../OUI ../OUI
t ../coucou/../../a ../../a
t /coucou/a /coucou/a
t /coucou//a /coucou/a
t / /
t // /
t //. /
t .// .
t /truc/ /truc

