#/bin/sh

fais()
{
	php -r '
		$i = exif_read_data($argv[1], "IFD0");
		if(isset($i["Orientation"]))
			switch($i["Orientation"])
			{
				case 6: echo "90\n"; break;
				case 8: echo "270\n"; break;
			}
	' "$1" |
	(
		image="$1"
		read tourne && jpegtran -rotate $tourne -outfile "$image.tournee" "$image"&& image="$image.tournee"
		texte="`echo "$image" | sed -e 's/.tournee//' -e 's/\.[a-zA-Z0-9]*$//'`"
		tesseract "$image" "$texte" &&
		echo "$1" >> /tmp/temp.EnTexte.$$.liste &&
		echo "$texte.txt" >> /tmp/temp.EnTexte.$$.liste
	)
}

liste="$1"
> /tmp/temp.EnTexte.$$.liste
ic=cat
iconv -f mac < "$liste" > /dev/null 2>&1 && ic="iconv -f mac"
cat "$liste" | $ic | while read fichier
do
	echo "=== `basename "$fichier"` ==="
	fais "$fichier"
done
tr '\012' '\000' < /tmp/temp.EnTexte.$$.liste | xargs -0 open
