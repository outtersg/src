tell application "iTunes"
	set liste to selection
	if number of items of liste is 0 then
		set liste to tracks of source 2
	end if
	set cheminTmp to POSIX file "/tmp/listeselection"
	try
		close access cheminTmp
	end try
	set tmp to open for access cheminTmp with write permission
	set eof tmp to 0
	repeat with piste in liste
		tell piste
			set lieu to location
			set chemin to POSIX path of lieu
			write (track number as string) & "	" & chemin & "	" & name & "	" & artist & "	" & composer & "	" & album & "	" & year & "	" & disc number & "	" & composer & "	" & artist & "	" & album artist & "	" & album & "	" & "Various artists" & linefeed to tmp as Çclass utf8È
		end tell
	end repeat
	close access tmp
end tell