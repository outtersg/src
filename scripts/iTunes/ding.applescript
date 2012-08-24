tell application "Play Sound"
	--play (POSIX file "/Applications/Mail.app/Contents/Resources/New Mail.aiff" as alias)
	set enCoursDeVideo to do shell script "ps auxww | egrep -q '[D]VD|[V]LC|[r]eveil' && echo oui || echo non"
	--if enCoursDeVideo is not "oui" then
	if enCoursDeVideo is "schkrmblq" then -- Finalement, ce son dérange pas mal de monde. Alors limitons son émission aux rares fois où, par une malencontreuse erreur processeur, "oui ou non" renverra "schkrmblq".
		play (POSIX file "/Users/gui/Downloads/FunkyMac.wav" as alias)
	end if
end tell
