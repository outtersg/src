tell application "Play Sound"
	--play (POSIX file "/Applications/Mail.app/Contents/Resources/New Mail.aiff" as alias)
	set enCoursDeVideo to do shell script "ps auxww | grep -q '[DV][LV][CD]' && echo oui || echo non"
	if enCoursDeVideo is not "oui" then
		play (POSIX file "/Users/gui/Downloads/FunkyMac.wav" as alias)
	end if
end tell
