on creer(quoi, nom, de, a)
	global dest
	tell application "iCal"
		set debut to start date of quoi
		if debut � ((current date) - (1 * days)) and debut < ((current date) + (90 * days)) then
			tell dest
				set nouveau to make new event at end of events with properties {start date:de, summary:nom, end date:a}
			end tell
		end if
	end tell
end creer

on copier(quoi, nom)
	tell application "iCal"
		my creer(quoi, nom, start date of quoi, end date of quoi)
	end tell
end copier

on copierPerso()
	tell application "iCal"
		repeat with i in events of calendar "Personnel"
			set mots to summary of i
			set mot to first word of mots
			my copier(i, mot)
		end repeat
	end tell
end copierPerso

on copierTrajetsPrepa()
	tell application "iCal"
		repeat with autres in {"Trajets", "Préparatifs"}
			repeat with i in events of calendar autres
				my copier(i, autres)
			end repeat
		end repeat
	end tell
end copierTrajetsPrepa

on copierTrajetsVersailles()
	tell application "iCal"
		repeat with i in events of calendar "Trajets"
			set titre to summary of i
			if titre contains "Versailles: " then
				my creer(i, characters 13 thru end of titre as string, start date of i, end date of i)
			else if titre contains "-> Versailles" then
				my creer(i, "Arrivée", end date of i, end date of i)
			else if titre contains "VerRG" or titre contains "VerChan" or titre contains "Chantiers" or titre contains "Montreuil" or titre contains "VerRD" or titre contains "<- Versailles" or titre contains "Porch" then
				my creer(i, "Départ", start date of i, start date of i)
			end if
		end repeat
	end tell
end copierTrajetsVersailles

tell application "iCal"
	launch
end tell

--tell application "System Events" to set visible of process "iCal" to false

tell application "iCal"
	global dest
	set dest to calendar "Tout"
	delete events of dest
	--my copierPerso()
	--my copierTrajetsPrepa()
	my copierTrajetsVersailles()
	
	-- Publication
	
	tell calendar "Tout"
		-- On sélectionne Tout en affichant un de ses événements créés pour l'occasion.
		set bidon to make new event at end of events
		show bidon
		delete bidon
	end tell
	
	activate -- System Events, espèce de gros naze!
	
end tell

tell application "System Events"
	tell process "iCal"
		click menu item "Actualiser" of menu "Calendrier" of menu bar item "Calendrier" of menu bar 1
		--		set visible to false
	end tell
end tell

delay 5

tell application "iCal"
	delete events of dest
	--	quit
end tell
