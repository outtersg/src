#!/bin/sh

case "$1" in
	carlo)
		dest="/Volumes/CARLOMAN/sauvegardes/ks/"
		commande=rs
		;;
	sb)
		dest="/Volumes/sauve bernard/sauvegardes/ks/"
		commande=rs
		;;
	sg)
		dest="/Volumes/FreeAgent Drive/Backup/ks"
		commande=rsnt
		;;
	006)
		dest="/Users/sauvegardes/ks."
		commande=o
esac

[ -z "$dest" ] && echo "# Utilisation: ouf.ks [carlo|sb|sg|006]" >&2 && exit 1

rs()
{
	rsync -XvrltDz --exclude-from=- root@k:/ "$dest"
}

rsnt()
{
	rsync -AXazv -e "ssh -p 443" --exclude-from=- root@ks31107.kimsufi.com:/ "$dest"
}

o()
{
	ouf -v -d root@k:/ "$dest"
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
