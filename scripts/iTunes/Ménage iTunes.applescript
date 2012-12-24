tell application "iTunes"
	repeat with i from (count of file tracks of first library playlist) to 1 by -1
		try
			if location of file track i of first library playlist as string is "missing value" then
				delete file track i of first library playlist
			end if
		end try
	end repeat
end tell