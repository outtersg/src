on open of fichiers
	-- Test: commenter l'on open et l'end open (1?re et derni?re lignes), et d?commenter la ligne suivante
	--set fichiers to {POSIX file "/tmp/a"}
	set cheminTemp to "/tmp/temp." & (random number from 0 to 1000000) & ".enmp3surcle"
	set fichierTemp to POSIX file cheminTemp
	set tmp to open for access fichierTemp with write permission
	repeat with fichier in fichiers
		set chemin to POSIX path of fichier
		write chemin & linefeed to tmp
	end repeat
	close access tmp
	-- http://macscripter.net/viewtopic.php?id=38680
	set moi to POSIX path of (path to me)
	set {TID, text item delimiters, i} to {text item delimiters, "/", ((moi ends with "/") as integer) + 1}
	set {dirname, text item delimiters} to {text 1 thru text item -(i + 1) of moi, TID}
	-- http://macscripter.net/viewtopic.php?id=32640
	tell application "Terminal"
		set fenetre to do script dirname & "/EnMp3SurCle.sh " & cheminTemp & " ; exit"
		repeat until fenetre's history contains "EnMp3SurCle"
			delay 1
		end repeat
		delay 1
		repeat until busy of fenetre is false
			delay 1
		end repeat
		close (first window whose selected tab is fenetre) saving no
	end tell
end open
