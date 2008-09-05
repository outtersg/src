#!/bin/sh

BIBLIO=/Users/gui/mp3
LISTE="/Users/gui/Music/iTunes/iTunes Music Library.xml"
PAR_PHP=oui

SCRIPTS=`which "$0"` ; SCRIPTS=`dirname "$SCRIPTS"` ; echo "$SCRIPTS" | grep -q '^/' || SCRIPTS="$PWD/$SCRIPTS" ; export SCRIPTS

xalan="$HOME/lib/xalan.jar"

[ "x$1" = x-q ] || osascript "$SCRIPTS/Ménage iTunes.scpt"
#osascript -e 'tell application "iTunes" to quit'
if false
then
	grep -v DOCTYPE "$LISTE" > /tmp/musique.xml
	java -jar "$xalan" -IN /tmp/musique.xml -XSL "$SCRIPTS/1.plist2xml.xsl" > /tmp/musique2.xml
	java -jar "$xalan" -IN /tmp/musique2.xml -XSL "$SCRIPTS/2.tri.xsl" > /tmp/musique3.xml
	"$SCRIPTS/3.conv" < /tmp/musique3.xml > $BIBLIO/-\[Liste\]-.iso-8859-1.html
fi

if [ $PAR_PHP != oui ] ; then
	sed -e 's@\$BIBLIO@'"$BIBLIO"'@g' < "$SCRIPTS/2.tri.ln.xsl" > /tmp/musique4.xsl
	java -jar "$xalan" -IN /tmp/musique2.xml -XSL /tmp/musique4.xsl | "$SCRIPTS/3.conv.ln" > /tmp/musique4.sh
	chmod u+x /tmp/musique4.sh
fi
cd $BIBLIO
rm -Rf ./-\[Classement\]-
mkdir ./-\[Classement\]-
cd ./-\[Classement\]-
mkdir ./ooooo
mkdir ./oooo
mkdir ./ooo
mkdir ./oo
mkdir ./o
if [ $PAR_PHP != oui ] ; then
	/tmp/musique4.sh
else
	php -d include_path=.:$HOME/src/util/php "$SCRIPTS/libenscript.php" "$LISTE" | xargs -0 -n 2 ln -s
fi
