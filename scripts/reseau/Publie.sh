#!/bin/sh

liste="$1"
http="http://dd.gclo.fr"

listeEnPressePapier()
{
	# COPIE: eu.outters.fichiersCopiesEnPressePapier
	sed -e 's#/*$##' < "$liste" | php -r 'while(($l = fgets(STDIN)) !== false) { echo "'"$http"'/".rawurlencode(basename(rtrim($l, "\n")))."\n"; }' | pbcopy
	echo "Les futures URL définitives sont copiées, vous pouvez faire un Pomme-V pour les insérer dans un mél. Cependant les URL ne seront véritablement actives que lorsque le transfert qui suit sera terminé." >&2
}

listeEnPressePapier

echo "gclo.fr:internet/partage/" >> "$liste"
sed -e 's#/*$##' < "$liste" | tr '\012' '\000' | xargs -0 rsync -av --progress
echo "Transfert terminé. Vous pouvez terminer le programme en faisant un Ctrl-C. Cette fenêtre s'éteindra sinon d'elle-même d'ici une heure." >&2
sleep 3600
rm "$liste"
