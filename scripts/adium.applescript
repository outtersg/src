global Adium
set Adium to 0.8

global theConferenceServer
set theConferenceServer to "conference.localhost"
global theHandle
set theHandle to "Magic"
global theAccount
set theAccount to "gui@kador (Jabber)"

global menuCompte
global menuJoindre
global menuFichier
global fenetreJoindre
global boutonJoindre
if Adium ³ 0.8 then
	set menuCompte to "gui@kador"
	set menuFichier to "Fichier"
	set menuJoindre to "Se joindre ˆ une conversation..."
	set fenetreJoindre to "Joindre la discussion"
	set boutonJoindre to "Joindre"
else
	set menuCompte to "gui@kador (Jabber)"
	set menuFichier to "File"
	set menuJoindre to "Join Group Chat..."
	set fenetreJoindre to "Join Chat"
	set boutonJoindre to "Join"
end if

-- Merci ˆ jayoung!
-- <http://people.engr.ncsu.edu/jayoung/site/pages/adium-group-chat-bookmarks-via-applescript>
on joindre(theChatRoom)
	tell application "System Events"
		tell application process "Adium"
			-- click menu item "Preferences..." of menu "Adium" of menu bar item "Adium" of menu bar 1
			-- click the third button of the toolbar of the front window
			click menu item menuJoindre of menu menuFichier of menu bar item menuFichier of menu bar 1
			click pop up button 1 of window fenetreJoindre
			pick menu item theAccount of menu of pop up button 1 of window fenetreJoindre
			(* picking the account from the pop up causes the fields in the dialog
                   to clear, so we have to delay so the rest of our text isn't wiped out *)
			delay 1
			set value of text field 5 of window fenetreJoindre to theConferenceServer
			set value of text field 4 of window fenetreJoindre to theHandle
			(* this is a little stupid, apparently Adium will only activate the "join"
                   button if and when you type a key into the Chat Room Name field *)
			select text field 6 of window fenetreJoindre
			keystroke "i"
			set value of text field 6 of window fenetreJoindre to theChatRoom
			click button boutonJoindre of window fenetreJoindre
		end tell
	end tell
end joindre

activate application "Adium"
tell application "System Events"
	tell application process "Adium"
		try
			if Adium ³ 0.8 then
				click menu item "Disponible" of first menu of menu item menuCompte of menu "Statuts" of menu bar item "Statuts" of menu bar 1
			else
				click menu item ("Connect: " & menuCompte) of menu "File" of menu bar item "File" of menu bar 1
			end if
			delay 2
		end try
	end tell
end tell
joindre("underground", "Pushpin", "Black Background")
--joindre("darcs", "Eclipse", "Wood Cherry")
joindre("agricoll", "Eclipse", "Wood Cherry")
