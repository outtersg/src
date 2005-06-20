set delai to 0.2 -- Avec mes réglages, le temps qu'un menu déroulant soit renroulé.
set groupe to 5 -- 2 dans Safari 1.2

--activate application "Safari"
tell application "System Events"
	tell application process "Safari"
		try
			click pop up button 1 of UI element 16 of UI element 1 of scroll area 1 of group groupe of window "guillaume.outters - Webmail Free"
			pick menu item "Non lu" of menu of pop up button 1 of UI element 16 of UI element 1 of scroll area 1 of group groupe of window "guillaume.outters - Webmail Free"
			delay delai
			-- Marquer comme : est le pop up button 2 of UI element 16
			click pop up button 1 of UI element 17 of UI element 1 of scroll area 1 of group groupe of window "guillaume.outters - Webmail Free"
			pick menu item 9 of menu of pop up button 1 of UI element 17 of UI element 1 of scroll area 1 of group groupe of window "guillaume.outters - Webmail Free"
			click UI element 1 of UI element 17 of UI element 1 of scroll area 1 of group groupe of window "guillaume.outters - Webmail Free"
		end try
	end tell
end tell
