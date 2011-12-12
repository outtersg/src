#!/bin/sh

serveur=k
nom=ks
[ "x$1" = x-l ] && serveur=l && nom=l && shift

case "$1" in
	carlo)
		dest="/Volumes/CARLOMAN/sauvegardes/$nom/"
		commande=rs
		;;
	sb)
		dest="/Volumes/sauve bernard/sauvegardes/$nom/"
		commande=rs
		;;
	sg)
		dest="/Volumes/FreeAgent Drive/Backup/$nom"
		commande=rsnt
		;;
	006)
		dest="/Users/sauvegardes/$nom."
		commande=o
esac

[ -z "$dest" ] && echo "# Utilisation: ouf.ks [carlo|sb|sg|006]" >&2 && exit 1

rs()
{
	rsync -XvrltDz --exclude-from=- root@$serveur:/ "$dest"
}

rsnt()
{
	rsync -AXazv -e "ssh -p 443" --exclude-from=- root@$serveur:/ "$dest"
}

o()
{
	ouf -v -d root@$serveur:/ "$dest"
}

(
cat <<TERMINE
- /dev
- /home/local/share
- /home/local/ghc-*
- /home/local/ocaml-*
- /home/local/python-*
- /home/local/vim-*
- /home/ports
- /home/*/sauvegardes
- /home/swap*
- /proc
- /rescue
- /sbin
- /tmp
- /usr/ports
- /usr/compat
- /usr/share
- /usr/src
- /var/db/freebsd-update
- /var/tmp
- **/temp/*.128.jpg
- **/temp/*.cache
- **/temp/*.session
- **/temp/*.sessions
- **/imagettes
TERMINE
) | $commande
