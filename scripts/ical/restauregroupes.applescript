-- Générer les groupes: copier la première colonne d'un tableur groupe;personne
-- pbpaste | sort -u | sed -e 's/^\(.*\)$/make new group with properties {name:"\1"}/' | pbcopy
-- Générer les personnes: copier les deux colonnes
-- pbpaste | sed -e 's/^\([^     ]*\)    \([^    ]*\)$/add person named "\2" to group named "\1"/' | pbcopy
-- Il sera sans doute nécessaire de retaper la liste à la main (les titres (« père ») devraient être inclus dans le tableur pour que l'osascript reconnaisse les personnes; les personnes à prénom seul ne passent pas, etc.)

tell application "Address Book"
	-- Coller ici les:
	--make new group with properties {name:"Amis enfance"}
	
	-- Coller ici les:
	-- add person named "Benoît et Cécile Begassat (Damour)" to group named "Amis enfance"
	save
end tell