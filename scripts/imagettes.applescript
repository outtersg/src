on open liste
	
	tell application "Image Events" to launch
	tell application "Image Events"
		repeat with fichier in liste
			
			try
				set zimage to open fichier
				scale zimage to size 160
				set chemin to path of fichier & ".imagette.png"
				save zimage as PNG in file chemin
				close zimage
			on error error_message
				tell application "Finder" to display dialog error_message
			end try
			
		end repeat
	end tell
	
end open

on run liste
	set i to 0
	repeat with i from 1 to count of liste
		set item i of liste to POSIX file (item i of liste)
	end repeat
	open liste
end run
