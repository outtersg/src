on run argv
	tell application "Mail"
		set b to mailbox "INBOX/Spam" of account "Free"
		repeat with n from 1 to 16
			set m to message n of b
			if subject of m is item 1 of argv then
				set titre to subject of m
				move m to mailbox "INBOX" of account "Famille"
				return titre
			end if
		end repeat
	end tell
end run
