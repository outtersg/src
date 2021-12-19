#!/bin/sh

Delicat() { local s2 ; while [ -h "$s" ] ; do s2="`readlink "$s"`" ; case "$s2" in [^/]*) s2="`dirname "$s"`/$s2" ;; esac ; s="$s2" ; done ; } ; SCRIPTS() { local s="`command -v "$0"`" ; [ -x "$s" -o ! -x "$0" ] || s="$0" ; case "$s" in */bin/*sh) case "`basename "$s"`" in *.*) true ;; *sh) s="$1" ;; esac ;; esac ; case "$s" in [^/]*) local d="`dirname "$s"`" ; s="`cd "$d" ; pwd`/`basename "$s"`" ;; esac ; Delicat ; s="`dirname "$s"`" ; Delicat ; SCRIPTS="$s" ; } ; SCRIPTS
export PATH="$SCRIPTS:$PATH"

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
- /home/jails/*/usr/monlocal/_rspamd*/var/log
+ /home/jails/*/usr/monlocal/_*
- /home/jails/*/usr/monlocal/*
# Les src sont des remontages de celui de bas, seul à mériter sauvegarde donc.
+ /home/jails/bas/usr/home/bas/src
- /home/jails/*/usr/home/*/src
- /home/jails/**/bas/src/**/vendor
- /home/jails/bas/usr/home/bas/.cabal
- /home/jails/bas/usr/home/bas/.cargo/registry
- /home/jails/bas/usr/home/bas/.stack
- /home/jails/bas/usr/home/bas/paquets
- /home/jails/bas/usr/home/bas/src.*
- /home/jails/bas/usr/home/bas/tmp/paquets
- /home/jails/bas/usr/home/bas/tmp/*-[0-9]*
- /home/jails/bas/usr/home/bas/tmp/llvm*
- /home/jails/bas/usr/home/bas/tmp/rust*
- /home/jails/bas/usr/home/bas/tmp/[0-9][0-9]
- /home/jails/bas/usr/home/bas/tmp/[0-9][0-9][0-9]
- /home/jails/bas/usr/home/bas/tmp/[0-9][0-9][0-9][0-9]
- /home/jails/bas/usr/home/bas/tmp/[0-9][0-9][0-9][0-9][0-9]
- /home/jails/bas/usr/home/bas/tmp/[0-9][0-9][0-9][0-9][0-9][0-9]
# À FAIRE: exclure tous les [a-z] (seuls les _ sont censés porter des fichiers de conf), mais seulement en dessous d'eux pour garder au moins la liste de dossiers.
# + conserver quelques fichiers personnalisés, comme php-*/lib/php.ini
+ /home/jails/bas*/usr/local
- /home/jails/bas*/usr/local/clang-*
- /home/jails/bas*/usr/local/cmake-*
- /home/jails/bas*/usr/local/dovecot-*
- /home/jails/bas*/usr/local/gcc-*
- /home/jails/bas*/usr/local/ghc-*
- /home/jails/bas*/usr/local/gettext-*
- /home/jails/bas*/usr/local/git-*
- /home/jails/bas*/usr/local/glib-*
- /home/jails/bas*/usr/local/icu-*
- /home/jails/bas*/usr/local/llvm-*
- /home/jails/bas*/usr/local/mysql-*
- /home/jails/bas*/usr/local/ocaml-*
- /home/jails/bas*/usr/local/perl-*
- /home/jails/bas*/usr/local/postgresql-*
- /home/jails/bas*/usr/local/python-*
- /home/jails/bas*/usr/local/rspamd-*
- /home/jails/bas*/usr/local/rust-*
- /home/jails/bas*/usr/local/vim-*
- /home/jails/bas*/usr/bin
- /home/jails/bas*/usr/lib
- /home/jails/bas*/usr/lib32
- /home/jails/bas*/usr/libexec
- /home/jails/bas*/usr/share/man
# MySQL binaire (donc complète chaque jour: 100 Mo), utilisée seulement par Roundcube.
- /home/jails/bdd/usr/home/bdd/var/db/mysql
- /home/jails/mel/usr/home/mel/var/mail/*/*/.Trash
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
