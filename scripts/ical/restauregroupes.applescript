-- G�n�rer les groupes: copier la premi�re colonne d'un tableur groupe;personne
-- pbpaste | sort -u | sed -e 's/^\(.*\)$/make new group with properties {name:"\1"}/' | pbcopy
-- G�n�rer les personnes: copier les deux colonnes
-- pbpaste | sed -e 's/^\([^     ]*\)    \([^    ]*\)$/add person named "\2" to group named "\1"/' | pbcopy
-- Il sera sans doute n�cessaire de retaper la liste � la main (les titres (��p�re��) devraient �tre inclus dans le tableur pour que l'osascript reconnaisse les personnes; les personnes � pr�nom seul ne passent pas, etc.)

tell application "Address Book"
	-- Coller ici les:
	--make new group with properties {name:"Amis enfance"}
	
	-- Coller ici les:
	-- add person named "Beno�t et C�cile Begassat (Damour)" to group named "Amis enfance"
	save
end tell