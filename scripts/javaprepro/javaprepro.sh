#!/bin/sh
# 
# javaprepro.sh - utilise javaprepro pour [dé]commenter des bouts de code situés entre //#ifdef|ifndef|else|endif
# 
# -- PB User Script Info --
# %%%{PBXName=JavaPrepro}%%%
# %%%{PBXInput=Selection}%%%
# %%%{PBXOutput=ReplaceSelection}%%%

echo -n "%%%{PBXSelection}%%%"
echo `osascript << FIN_SCRIPT
tell application "Project Builder"
	display dialog "Options:" default answer ""
end tell
text returned of the result
FIN_SCRIPT
` <&0
echo -n "%%%{PBXSelection}%%%"

