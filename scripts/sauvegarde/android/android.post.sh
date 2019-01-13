#!/bin/sh

set -e

SCRIPTS="`command -v "$0"`" ; [ -x "$SCRIPTS" -o ! -x "$0" ] || SCRIPTS="$0" ; case "`basename "$SCRIPTS"`" in *.*) true ;; *sh) SCRIPTS="$1" ;; esac ; case "$SCRIPTS" in /*) ;; *) SCRIPTS="`pwd`/$SCRIPTS" ;; esac ; delie() { while [ -h "$SCRIPTS" ] ; do SCRIPTS2="`readlink "$SCRIPTS"`" ; case "$SCRIPTS2" in /*) SCRIPTS="$SCRIPTS2" ;; *) SCRIPTS="`dirname "$SCRIPTS"`/$SCRIPTS2" ;; esac ; done ; } ; delie ; SCRIPTS="`dirname "$SCRIPTS"`" ; delie
PREFIXE="`basename "$0" .post.sh`"

cd "$SCRIPTS"

#- Modules ---------------------------------------------------------------------

# Recopie des photos vers une sauvegarde brute et exhaustive.
photos()
{
	# À FAIRE: ne pas recopier ceux qui auraient déjà été pris une fois (et par exemple purgés pour ancienneté trop prononcée, mais pourtant encore sur l'appareil photo). Soit un flute inversé (conf à lire dans la dest, pas dans la source), soit un truc manuel.
	
	s="$PREFIXE.dernier/DCIM/Camera"
	d="Photos/$PREFIXE"
	
	( cd "$s" && find . -type f ) | while read f
	do
		[ -e "$d/$f" ] || ln "$s/$f" "$d/$f"
	done
	
	# Peuplement du dossier au confluent de tous les appareils photo.
	
	photocopie --pousser "$d" 
}

# Met à disposition du téléphone une extraction de la bibliothèque musicale de l'ordi.
musique()
{
	if command -v mp3versdroid > /dev/null 2>&1
	then
		mp3versdroid
	fi
}

#- Enchaînement ---------------------------------------------------------------

photos
musique
