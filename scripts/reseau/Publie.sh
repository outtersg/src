#!/bin/sh

LC_ALL=C
LANG=C
export LC_ALL LANG

liste="$1"
ic=cat
iconv -f mac < "$liste" > /dev/null 2>&1 && ic="iconv -f mac"
sed -e 's#/*$##' < "$liste" | $ic > "$liste.1"
http="http://tmp.outters.eu"

listeEnPressePapier()
{
	# COPIE: eu.outters.fichiersCopiesEnPressePapier
	php -r 'while(($l = fgets(STDIN)) !== false) { echo "'"$http"'/".rawurlencode(basename(rtrim($l, "\n")))."\n"; }' < "$liste.1" | pbcopy
	echo ----------------
	pbpaste
	echo ----------------
	echo "Les futures URL définitives sont copiées, vous pouvez faire un Pomme-V pour les insérer dans un mél. Cependant les URL ne seront véritablement actives que lorsque le transfert qui suit sera terminé." >&2
}

retaillerImage()
{
	while read i
	do
		mogrify -resize 800x800 "$i"
	done
}

retaillerFilm()
{
	while read i
	do
		ffmpeg -loglevel panic -strict experimental -i "$i" -vf scale='-1:min(640\, ih*640/iw)' -y -strict experimental "$i.2.MOV" && mv "$i.2.MOV" "$i"
	done
}

convertir()
{
	moinsDeNMega=3
	taille="`tr '\012' '\000' < "$liste.1" | xargs -0 du -cm | tail -1 | cut -f 1`"
	if [ $taille -ge $moinsDeNMega ]
	then
		while read fichier
		do
			tmp=/tmp/temp.$$.Publie.copie # Sur Mac, on est sur le même disque, donc on peut faire des liens en dur.
			d="`dirname "$fichier"`"
			f="`basename "$fichier"`"
			mkdir -p "$tmp"
			( cd "$d" && find "$f" -print | cpio -p -al "$tmp" )
			echo "$tmp/$f"
			( cd "$tmp" && find "$f" -name \*.MOV | retaillerFilm )
			( cd "$tmp" && find "$f" -name \*.JPG -or -name \*.jpg | retaillerImage )
		done < "$liste.1" > "$liste.2"
		mv "$liste.2" "$liste.1"
		# À FAIRE: après le transfert, effacer nos fichiers temporaires.
	fi
}

# Concrètement, on peut établir la liste dès maintenant, car convertir() remplacera les fichiers sans changer leur nom, donc les URL résultantes.
listeEnPressePapier

convertir

echo "m:/tmp/tmp/" >> "$liste.1"
tr '\012' '\000' < "$liste.1" | xargs -0 rsync -av --progress
echo "Transfert terminé. Vous pouvez terminer le programme en faisant un Ctrl-C. Cette fenêtre s'éteindra sinon d'elle-même d'ici une heure." >&2
sleep 3600
rm "$liste" "$liste.1"
