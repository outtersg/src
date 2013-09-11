-- Coller ça dans un service Automator, avec Réceptions du service sélectionnées à Fichiers ou dossiers par exemple.
-- Pour configurer: chercher le /Users dans ce fichier et remplacer par le chemin du script à lancer.
-- Par rapport à un Droplet: on peut traiter les liens durs (cf. GereDropParScript.applescript).
on run {fichiers, parameters}
	set cheminTemp to "/tmp/temp." & (random number from 0 to 1000000) & ".enmp3surcle"
	set fichierTemp to POSIX file cheminTemp
	set tmp to open for access fichierTemp with write permission
	repeat with fichier in fichiers
		set chemin to POSIX path of fichier
		write chemin & linefeed to tmp
	end repeat
	close access tmp
	-- http://macscripter.net/viewtopic.php?id=32640
	tell application "Terminal"
		set fenetre to do script "/Users/gui/src/scripts/EnTexte.sh " & cheminTemp & " ; exit"
		--repeat until fenetre's history contains "EnMp3SurCle"
		--	delay 1
		--end repeat
		--delay 1
		--repeat until busy of fenetre is false
		--	delay 1
		--end repeat
		--close (first window whose selected tab is fenetre) saving no
	end tell
	return fichiers
end run
