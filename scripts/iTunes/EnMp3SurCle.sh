#!/bin/sh

LC_ALL=C
LANG=C
export LC_ALL LANG

liste="$1"
disque="/Volumes/NO NAME"
disque=/tmp
dest="$disque/Musique"

while [ ! -d "$disque" ]
do
	echo "# Veuillez insérer la clé USB \"`basename "$disque"`\", puis appuyez sur la touche Entrée." >&2
	read rien
done

mkdir -p "$dest"
cat "$liste" | while read fichier
do
	echo "=== `basename "$fichier"` ===" >&2
	case "$fichier" in
		*.m4a|*.ogg)
			ffmpeg -y -v quiet -i "$fichier" -ab 192k "$dest/`basename "$fichier" | sed -e 's/\....$/.mp3/'`" < /dev/null
			;;
		*)
			cp "$fichier" "$dest/"
			;;
	esac
done

echo "Transfert terminé. Vous pouvez terminer le programme en faisant un Ctrl-C. Cette fenêtre s'éteindra sinon d'elle-même d'ici une heure." >&2
sleep 3600
rm "$liste"
