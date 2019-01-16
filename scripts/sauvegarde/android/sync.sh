#!/system/bin/sh

# Terminal Manager: raccourci bureau: .; . /sdcard/sauvegardes/bin/sync.sh ; sleep 20 ; exit
# En root, on ne fera que du rsync disque à disque, car pour l'heure je n'arrive pas à faire tourner les rsync-s/-ssh de termux et sshelper en root (il plante en Permission denied, ne voulant pas exécuter ssh).
# Peut-être chercher du côté de /system/xbin (http://www.jimklimov.com/2017/06/rsync-from-pc-to-android-to-pull-data.html).
# Pour l'heure on pourra travailler en deux étapes: en root, copie vers /mnt/sdcard; puis en normal, rsync "externe" de /mnt/sdcard vers l'extérieur.

# Pensez à chmod a+rx le bin et l'appli dont on va utiliser les binaires.
# En root:
# for i in "" /files /files/usr /files/usr/bin /files/usr/lib /files/usr/bin/rsync /files/usr/bin/ssh ; do chmod a+rx "/data/data/com.termux$i" ; done
# chmod a+rx /data/data/com.termux/files/usr/lib/lib*.so*

R=/mnt/sdcard/sauvegardes

vert()
{
	echo "[32m$*[0m"
}

gris()
{
	echo "[90m$*[0m"
}

echo "=== Sauvegarde système ==="

su -c "sh < $R/bin/systeme.sh"

echo "=== Transfert de la sauvegarde ==="

# Les ssh compilés codent en dur tous leurs fichiers de conf; on doit donc mentionner à la main tout ce que l'on veut surcharger.
ssh="ssh -F $R/.ssh/config -o UserKnownHostsFile=$R/.ssh/known_hosts -i $R/.ssh/id_rsa"

export PATH="/data/data/com.termux/files/usr/bin:/data/data/com.arachnoid.sshelper/bin:$PATH"
export LD_LIBRARY_PATH="/data/data/com.termux/files/usr/lib"

export TMPDIR="$HOME/tmp"
mkdir -p "$TMPDIR"

testerDest()
{
	local n=0
	[ "x$1" = x-n ] && shift && n="$1" && shift || true
	local hote dest="$1"
	hote="`echo "$dest" | cut -d : -f 1`"
	$ssh -o ConnectTimeout=5 "$hote" true < /dev/null && echo "$dest" > "$TMPDIR/`printf "%03.3d" "$n"`.`echo "$dest" | sed -e 's/[^_a-zA-Z0-9]//g'`.dest"
}

dests()
{
	# A-t-on des hôtes à adresse dynamique (à retrouver sur le réseau local)?
	if grep -q '^<' < "$R/sync.dests"
	then
		gris "Résolution des alias dynamiques sur le réseau local…" >&2
		TMP="$TMPDIR"
		. "$R/bin/voisinage.sh"
		rl_voisinsCopainsSsh "$R/.ssh/known_hosts" | while read ip proto cle rien
		do
			# Retrouve-t-on l'alias correspondant à cette clé dans notre known_hosts?
			grep -F "$cle" | while read alias rien
			do
				echo "/^Host $alias/{
a\\
HostName $ip
a\\
HostKeyAlias $alias
}"
			done < "$R/.ssh/known_hosts" || true
		done > "$TMPDIR/reconfig.sed"
		sed -f "$TMPDIR/reconfig.sed" < "$R/.ssh/config" > "$TMPDIR/config"
		tr -d '<>' < "$R/sync.dests" > "$TMPDIR/sync.dests"
		ssh="`echo "$ssh" | sed -e "s#-F [^ ]*/config#-F $TMPDIR/config#"`"
		_dests "$TMPDIR/sync.dests"
	else
		_dests "$R/sync.dests"
	fi
}

_dests()
{
	gris "Recherche des serveurs de sauvegarde disponibles…" >&2
	local fDests="$1"
	local numLigne=0
	rm -f "$TMPDIR/"*.dest 2> /dev/null
	while read dest
	do
		numLigne=`expr $numLigne + 1`
		testerDest -n $numLigne "$dest" &
	done < "$fDests"
	wait
	cat "$TMPDIR/"*.dest | head -1
}

dests > "$TMPDIR/"dest
dest="`cat "$TMPDIR/dest"`"
	
	printf "%s" "-> " ; vert "$dest"

	export TMPDIR="$HOME/tmp" # Va savoir pourquoi, si je ne réexporte pas, il est incapable de le détecter lorsque le répertoire vient d'être créé, pour le heredoc suivant.
	sh "$R/bin/ouf" --sans-acl -r recycler -v --ssh "$ssh" -d /mnt/sdcard/ "$dest." <<TERMINE
- **/.thumbnails
- **/albumthumbs
- **/cache
- **/uil-cache
- /Android/data/com.google.android.apps.maps/testdata
- /Android/data/com.google.android.googlequicksearchbox
- /Android/data/com.microsoft.skydrive
- /Android/media/com.google.android.talk/Ringtones
- /Download
+ /Music/SoundRecords
- /Music/*
- /TWRP/BACKUPS
- /jumobile/recyclebin
TERMINE
	
	echo "=== Synchro musique ==="

	local ddest="`echo "$dest" | cut -d : -f 2-`"
	local prefixe="`basename "$ddest" | sed -e 's#\.*$##'`"
	ddest="`dirname "$ddest"`"
	$ssh "$hote" "cd \"$ddest\" && [ -x \"$prefixe.post.sh\" ] && \"./$prefixe.post.sh\"" # Censé sécuriser les images, et lancer un mp3versdroid, par exemple.
	# cf. https://askubuntu.com/a/343740
	rsync -rvl --size-only --delete --exclude SoundRecords -e "$ssh" "$hote:/tmp/mp3/" /mnt/sdcard/Music/

	echo "=== Fini ==="
	
	echo "Vous pouvez maintenant fermer ce terminal."
