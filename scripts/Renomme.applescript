on open of fichiers
	-- Test: commenter l'on open et l'end open (1ère et dernière lignes), et décommenter la ligne suivante
	--set fichiers to {POSIX file "/tmp/a"}
	set nouveauNom to display dialog "Renommer en?" default answer ""
	set nouveauNom to the text returned of nouveauNom
	set cheminTemp to "/tmp/temp." & (random number from 0 to 1000000) & ".renomme"
	set fichierTemp to POSIX file cheminTemp
	set tmp to open for access fichierTemp with write permission
	write nouveauNom & linefeed to tmp as «class utf8»
	repeat with fichier in fichiers
		set chemin to POSIX path of fichier
		write chemin & linefeed to tmp as «class utf8»
	end repeat
	close access tmp
	-- http://macscripter.net/viewtopic.php?id=38680
	set moi to POSIX path of (path to me)
	set {TID, text item delimiters, i} to {text item delimiters, "/", ((moi ends with "/") as integer) + 1}
	set {dirname, text item delimiters} to {text 1 thru text item -(i + 1) of moi, TID}
	do shell script "php " & dirname & "/Renomme.php " & cheminTemp
end open