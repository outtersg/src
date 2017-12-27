#!/bin/sh

serveur=k
nom=ks
[ "x$1" = xm ] && serveur=root.outters.eu && nom=m && shift && commande="$commande -x +/home --prune-empty-dirs" # m (k n°3); le --prune-empty-dirs car le Union FS crée des tonnes de dossiers vides (voir le man union_fs, BUGS).
[ "x$1" = x-l ] && serveur=l && nom=l && shift # l (k n°2)
[ "x$1" = x-ls ] && serveur=l && nom=ls && shift && commande="$commande -l l" # l, toutes les semaines.
[ "x$1" = x-r ] && commande="$commande $1 $2" && shift && shift

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
		commande="o $commande"
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
	ouf "$@" -v -d root@$serveur:/ "$dest"
}

(
cat <<TERMINE
- /dev
- /home/jails/*/basejail
- /home/jails/*/dev
- /home/jails/*/proc
- /home/jails/*/rescue
- /home/jails/*/tmp
- /home/jails/*/usr/local/
+ /home/jails/*/usr/monlocal/_*
- /home/jails/*/usr/monlocal/*
- /home/jails/bas/usr/home/bas/.cabal
- /home/jails/bas/usr/home/bas/.cargo/registry
- /home/jails/bas/usr/home/bas/.stack
- /home/jails/bas/usr/home/bas/paquets
- /home/jails/bas/usr/home/bas/src.*
- /home/jails/bas/usr/home/bas/tmp/paquets
+ /home/jails/basejail/usr/local
- /home/jails/basejail/usr/local/clang-*
- /home/jails/basejail/usr/local/gcc-*
- /home/jails/basejail/usr/local/ghc-*
- /home/jails/basejail/usr/local/llvm-*
- /home/jails/basejail/usr/local/ocaml-*
- /home/jails/basejail/usr/local/perl-*
- /home/jails/basejail/usr/local/python-*
- /home/jails/basejail/usr/local/vim-*
- /home/jails/basejail/usr/bin
- /home/jails/basejail/usr/lib
- /home/jails/basejail/usr/lib32
- /home/jails/basejail/usr/libexec
- /home/jails/basejail/usr/share/man
- /home/jails/sauvegardes/usr/home/sauvegardes/sauvegardes
# Pijul crée ses pristine comme un méga fichier virtuel (taille visible: 4 To).
- **/.pijul/pristine
- /home/jails/*/usr/home/*/.cache
- /home/jails/*/usr/home/*/.cargo/registry
- /=================
- /dev
- /home/gui/.cabal
- /home/gui/paquets
- /home/gui/sauvegardes/asterix.*
- /home/gui/sauvegardes/falbala.*
- /home/gui/sauvegardes/photos
- /home/gui/tmp/camera
- /home/gui/tmp/paquets
- /home/gui/var/postgresql/base
- /home/local/share
- /home/local/ghc-*
- /home/local/ocaml-*
- /home/local/python-*
- /home/local/vim-*
- /home/ports
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
- var/run/dovecot
- **/temp/*.128.jpg
- **/temp/*.cache
- **/temp/*.session
- **/temp/*.sessions
- **/imagettes
TERMINE
) | $commande
