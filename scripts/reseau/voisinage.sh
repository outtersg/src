# Copyright (c) 2019 Guillaume Outters
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

# Utilitaires pour détecter quelques copains (au sens SSH) sur le réseau local.
# Fait laborieusement à peu près la même chose que mDNS.

# Les fonctions sont préfixées rl_ comme Réseau Local.

if [ -z "$TMP" ]
then
	if [ -d /tmp -o -L /tmp ]
	then
		TMP=/tmp
	else
		TMP="`pwd`"
	fi
fi

rl_ipDiffu()
{
	(
		`command -v ip 2> /dev/null >&2` && ip address
		`command -v ifconfig 2> /dev/null >&2` && ifconfig
	) | sed -E -e '/^[ 	]*inet.*(broadcast|Bcast|brd)[ :][ :]*([0-9.]*).*$/!d' -e 's##\2#' | sort -u
		
}

rl_ping()
{
	case `uname` in
		Linux) ping -b -c 4 -t 2 -w 3 "$@" ;;
		*) ping -c 4 -t 2 "$@" ;;
	esac | sed -e '/.* from /!d' -e 's///' -e 's/:.*//' | sort -u
}

rl_voisins()
{
	local ip
	rl_ipDiffu | while read ip
	do
		rl_ping "$ip"
	done
}

rl_voisinsSsh()
{
	local ip
	# À FAIRE: si ssh-keyscan est présent, s'en servir.
	rl_voisins > "$TMP"/temp.reseaulocal.$$.voisins
	while read ip
	do
		( ssh -q -n -o ConnectTimeout=2 -o BatchMode=true -o UserKnownHostsFile="$TMP"/temp.reseaulocal.$$.kh.$ip -o StrictHostKeyChecking=no personne@$ip true < /dev/null > /dev/null 2>&1 ) &
	done < "$TMP"/temp.reseaulocal.$$.voisins
	wait
	cat "$TMP"/temp.reseaulocal.$$.kh.*
	rm -f "$TMP"/temp.reseaulocal.$$.kh.* "$TMP"/temp.reseaulocal.$$.voisins
}

rl_copainsSsh()
{
	local nom proto cle reste
	local connus="$1"
	if [ -z "$connus" ] ; then connus="$HOME/.ssh/known_hosts" ; fi
	while read nom proto cle reste ; do echo "$cle" ; done < "$connus" > "$TMP"/temp.reseaulocal.$$.cles
	grep -F -f "$TMP"/temp.reseaulocal.$$.cles
}

rl_voisinsCopainsSsh()
{
	rl_voisinsSsh | rl_copainsSsh "$@"
}
