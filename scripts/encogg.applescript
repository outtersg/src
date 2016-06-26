on run argv
	set cheminTmp to POSIX file (item 1 of argv)
tell application "iTunes"
	set liste to selection
	if number of items of liste is less than 2 then
		repeat with cetteSource in sources
			if kind of cetteSource is audio CD then
				set liste to tracks of cetteSource
			end if
		end repeat
	end if
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
end run
