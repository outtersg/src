tell application "iTunes"
	next track
	repeat until artist of current track is "" and composer of current track is not ""
		next track
	end repeat
end tell
