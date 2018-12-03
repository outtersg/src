#!/system/bin/sh
# En root, on ne fera que du rsync disque à disque, car pour l'heure je n'arrive pas à faire tourner les rsync-s/-ssh de termux et sshelper en root (il plante en Permission denied, ne voulant pas exécuter ssh).
# Peut-être chercher du côté de /system/xbin (http://www.jimklimov.com/2017/06/rsync-from-pc-to-android-to-pull-data.html).
# Pour l'heure on pourra travailler en deux étapes: en root, copie vers /mnt/sdcard; puis en normal, rsync "externe" de /mnt/sdcard vers l'extérieur.

BIN=/data/user/0/com.arachnoid.sshelper/bin

export PATH="$BIN:$PATH"

(
rsync --delete -av --exclude-from=- / /mnt/sdcard/sauvegardes/systeme/ <<TERMINE
- **/app_ads_cache
- **/app_sslcache
- **/app_webview
- appid
- **/cache
- clear_userid
- **/code_cache
- excluded_userids
- **/shaders
- packages_gid.list
- remove_userid
- **/GPUCache
- **/*.apk
- **/*.dex
- **/*.odex
- *.realm.management
- *.realm.note
- **/*.so
- **/*.so.[0-9]*
- /acct
- /cache
- /config/usb_gadget
- /dev
- /data/clipboard
- /data/dalvik-cache
- /data/data/com.android.captiveportallogin
- /data/data/com.google.android.apps.maps/files/DATA_ShortTermStorage*
- /data/data/com.google.android.gms/app_bound_sslcache
- /data/data/com.google.android.gms/app_place_inference_data_index
- /data/data/com.google.android.gms/databases/playlog.db*
- /data/data/com.google.android.gms/files/AppDataSearch
- /data/data/com.google.android.gms/snet/leveldb/snet_sb_blacklist_*
- /data/data/com.google.android.googlequicksearchbox
- /data/data/com.samsung.android.app.aodservice/shared_prefs/pref_aod_display_time.xml
- /data/data/com.samsung.android.scloud
- /data/data/com.samsung.android.slinkcloud
- /data/data/com.samsung.svoice.sync
- /data/data/com.sncf.ouigo/files/default.realm.management
- /data/data/com.sec.android.app.samsungapps
- /data/data/com.sec.android.gallery3d
- /data/data/com.sec.enterprise.knox.*
- /data/data/com.sec.svoice*
- /data/data/com.waze/waze
- /data/data/de.axelspringer.yana.zeropage
- /data/data/edu.berkeley.cs.amplab.carat.android
- /data/magisk.img
- /data/media
- /data/misc/profiles
- /data/misc/tima
- /data/misc/wifi/sockets
- /data/system/dropbox
- /data/system/gps
- /data/system/notification_log.db*
- /data/system/ndebugsocket
- /data/system/netstats
- /data/system/procstats
- /data/system/usagestats
- /data/system_ce/0/recent_images
- /data/system_ce/0/recent_tasks
- /data/user_de/0/com.android.bluetooth
- /mnt
- /proc
- /storage
- /sys
- /system
TERMINE
) 2>&1 | grep -v '/$' | egrep -v "(mknod|readlink|symlink).*(Operation not permitted|Permission denied)" # Filtrages erreurs / retransmis inévitables.
