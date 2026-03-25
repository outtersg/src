# Enrichissement d'un diff -u en allant piocher dans les fichiers concernés les infos enrichies.
# Utilisation: diff -uw libellés.0 libellés.1 | awk -f dcb.awk - complet.0 complet.1
# Les libellés.x sont l'extraction des colonnes à comparer depuis les fichiers complet.x.
# Les complet.x ont donc une structure:
#   <méta 0> <méta 1> <libellé>
BEGIN {
	# Nombre de colonnes informatives.
	nInfos = 2; # À FAIRE: rendre paramétrable.
	tHachage = 9; # À FAIRE: décoder en dur.
	bHachage = substr("                                 ", 1, tHachage);
	
	# f: fichiers; p: positions; l: lignes.
	f[0] = ARGV[2]; delete ARGV[2];
	f[1] = ARGV[3]; delete ARGV[3];
	
	p[0] = p[1] = 0;
}
function av(numg, numd, absolu) {
	num[0] = numg; num[1] = numd;
	for(i = 2; --i >= 0;)
	{
		if(!absolu) num[i] = p[i] + num[i];
		while(p[i] < num[i])
		{
			getline l[i] < f[i];
			n = split(l[i], li);
			taille = 0;
			for(j = 0; ++j <= nInfos;)
				taille += length(infos[i, j] = li[j]) + 1;
			l[i] = substr(l[i], taille + 1);
			++p[i];
		}
	}
	# Si on est en train de lire les lignes de diff, on les restitue en les enrichissant des champs supplémentaires.
	if(!absolu)
	{
		luni = substr($0, 2);
		# On constitue la version fusionnée en fonction des sources actives pour cette ligne (gauche pour un -, droite pour un +, les deux pour un espace).
		for(j = 0; ++j <= nInfos;)
			iuni[j] = "";
		for(i = 2; --i >= 0;)
		{
			if(!(i ? numd : numg)) continue; # Ligne non concernée (fichier gauche lors d'un + ou droit lors d'un -).
			if(luni != l[i]) print "# Ligne "p[i]" inattendue à "(i ? "droite" : "gauche")": "l[i]" au lieu de "luni > "/dev/stderr";
			
			for(j = 0; ++j <= nInfos;)
				if(!iuni[j])
					iuni[j] = infos[i, j];
				else if(iuni[j] != infos[i, j])
				{
					# Règles de fusion.
					if(j == 1) # date ISO
					{
						# Minimum.
						if(infos[i, j] < iuni[j]) iuni[j] = infos[i, j];
					}
					else
					{
						# Apposition.
						iuni[j] = iuni[j]" / "infos[i, j];
					}
				}
				iuni[j] = infos[i, j]""(iuni[j] && iuni[j] != infos[i, j] ? " / "iuni[j] : "");
		}
		# Spécificité du hachage (colonne 2): toujours affiché.
		# À FAIRE: décoder en dur.
		{
			j = 2;
			iuni[j] = "";
			for(i = -1; ++i < 2;)
				iuni[j] = iuni[j]"|"((i ? numd : numg) ? infos[i, j] : bHachage);
			iuni[j] = substr(iuni[j], 2);
			if(substr(iuni[j], 1, tHachage) == substr(iuni[j], tHachage + 2, tHachage))
				iuni[j] = substr(bHachage, 1, (tHachage + 1) / 2)""substr(iuni[j], 1, tHachage)""substr(bHachage, (tHachage + 1) / 2);
		}
		printf("%s ", substr($0, 1, 1));
		for(j = 0; ++j <= nInfos;)
			printf("%s ", iuni[j]);
		# À FAIRE: colorisation (- en rouge, + en vert).
		print luni;
	}
}
/^[-+]{3} / { next; }
/^@@ -[0-9]+,[0-9]+ \+[0-9]+,[0-9]+ @@$/ {
	# À FAIRE?: Afficher les lignes intermédiaires, ou des […] marquant l'espace?
	# À FAIRE?: Afficher aussi des … en fin de fichier, s'il reste des lignes communes.
	split($0, t, /[^0-9]+/);
	av(t[2] - 1, t[4] - 1, 1);
}
/^ / { av(1, 1); }
/^\+/ { av(0, 1); }
/^-/ { av(1, 0); }
