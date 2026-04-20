# GUIDON: mon patois de prise de notes / listes de tâches
# Gabarit Unifié pour l'Immortalisation Dépouillée et Organisée de Notes
# (et si je m'étais appelé Mark ç'aurait sans doute été MARKDON, mais je ne suis pas Mark)
BEGIN{
	entete = 1;
	for(i = 0; ++i < ARGC;)
	{
		if(ARGV[i] == "nu")
		{
			entete = 0;
			delete ARGV[i];
		}
	}
	niv = 0;
	prochniv = 0;
	lignevide = 0;
	para = 0;
	if(entete)
	while(getline <"/home/gui/src/scripts/texte/notes2html.html")
		print;
	puces["-"] = "lim";
	puces["+"] = "lip";
	puces["="] = "lieg";
	puces["*"] = "liet";
	puces["•"] = "";
	puces["?"] = "liq";
}
function affPrec(fin){
	if(!match($0, /./) && !fin)
	{
		++lignevide;
		return;
	}
	
	if(niv > 0)
		prec = prec"</li>";
	else if(!para && !fin && NR > 1)
		# À FAIRE?: les <p>? Mais ils me font chier avec leurs marges entre <p> et <ul> et compagnie.
		prec = prec""(lignevide ? "<br/>" : "")"<br/>";
	for(i = niv; --i >= prochniv;)
		prec = prec"</ul>";
	
	print prec;
	prec = "";
	
	if(prochniv > 0)
	{
		prepuce = "";
		if(puce ~ /^[0-9]+\.$/ && !puces[puce]) # Puces numériques.
		{
			pupuce = puce;
			sub(/\.$/, "", pupuce);
			prepuce = "<style type=\"text/css\">li.li"pupuce"::before { content: \""puce"\"; }</style>";
			puces[puce] = "li"pupuce;
		}
		if((puce = puces[puce]))
			puce = " class=\""puce"\"";
		prec = prepuce"<li"puce">"prec;
	}
	# À FAIRE?: utiliser de l'<ol> plutôt que de l'<ul> pour les listes ordonnées?
	if(prochniv > niv)
		prec = "<ul>"prec;
	
	niv = prochniv;
	prochniv = 0;
	lignevide = 0;
	if(para) --para;
}
{ gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;"); }
/[*][^*]*[*]/{
	while(match($0, /[*][^*]*[*]/))
		$0 = substr($0, 1, RSTART - 1)"<b>"substr($0, RSTART + 1, RLENGTH - 2)"</b>"substr($0, RSTART + RLENGTH);
}
/_/{
	# [:alnum:] ne reconnaît pas les accents; on utilise donc [^[:punct:][:space:]]
	while(match($0, /(^|[[:space:]])_[^[:punct:][:space:]][^_]*[^[:punct:][:space:]]_([[:punct:][:space:]]|$)/))
	{
		# A-t-on un signe de ponctuation ou espace à préserver avant et après les _ (ou bien est-on en début / fin de ligne, auquel cas on attaque directement avec le _)?
		if(substr($0, RSTART, 1) != "_") { ++RSTART; --RLENGTH; }
		if(substr($0, RSTART + RLENGTH - 1, 1) != "_") --RLENGTH;
		$0 = substr($0, 1, RSTART - 1)"<em>"substr($0, RSTART + 1, RLENGTH - 2)"</em>"substr($0, RSTART + RLENGTH);
	}
}
/\/!\\/ { gsub(/\/!\\/, "<b>⚠</b>"); }
{ retravail(); }
# Façon LDAP, une ligne commençant par l'indentation mais sans tirets est la continuité du tiret.
niv && /^\t*[^-+*=•?\t]/{
	# Le départ doit être constitué d'au moins autant de tabulations que l'indentation structurelle.
	# Tolérance à une tabulation utilisée comme premier niveau d'indentation visuelle.
	# Le cas échéant les tabulations sont préservées telles quelles (on considère que c'est du code indenté qui y est collé), avec une indentvis donc ramenée à 0.
	# À FAIRE?: signaler une erreur d'indentation, par exemple une tabulation supplémentaire alors que la micro-indentation de proximité était en espaces?
	if(substr($0, 1, niv - 1) ~ /^\t*$/ && (substr($0, niv, indentvis = length(nivvis)) == nivvis || (nivvis ~ /^  / && substr($0, niv, 1) == "\t" && !(indentvis = 0))))
	{
		prec = prec"<br/>"substr($0, niv + indentvis);
		next;
	}
}
/^\t*([-+*=•?]|[1-9][0-9]*\.) /{
	match($0, /^\t*/);
	prochniv = RLENGTH + 1;
	$0 = substr($0, prochniv);
	match($0, " ");
	puce = substr($0, 1, RSTART - 1);
	nivvis = substr($0, 1, RSTART); # Niveau visuel: les espaces supplémentaires qui permettent d'aligner la suite avec l'après-puce.
	gsub(/[^\t ]/, " ", nivvis); # Les puces se transposeront à partir de la ligne suivante en micro-indentation à espaces.
	# À FAIRE: un prochniv adaptable, lorsque par exemple sous un "1. " (3 caractères) on n'indente que de "  " (2 caractères), pour coller à un alignement type "• ". En ce cas la première ligne sous la puce devrait avoir une tolérance en "2 ou 3" (voire 1?), mais les suivantes s'alignent sous cette dernière et pour elles tout espace en plus est de l'indentation graphique (à restituer).
	$0 = substr($0, RSTART + 1);
}
/^=== /{
	sub(/^=== /, "<h3>");
	sub(/ ===$/, "</h3>");
	para = 2;
}
/^--- /{
	sub(/^--- /, "<h4>");
	sub(/ ---$/, "</h4>");
	para = 2;
}
/^-- .* --$/{
	sub(/^-- /, "<h5>");
	sub(/ --$/, "</h5>");
	para = 2;
}
{ affPrec(); }
/^$/{ ++lignevide; }
/./ { lignevide = 0; }
function retravail() {
	### Retravail ###
	
	# URL sèches:
	# Expression de reconnaissance des URL: à synchroniser avec Notes.vim.
	gsub(/https*:\/\/([^ ),;:]+|:[^ ])+/, "<a href=\"&\">&</a>");
	# URL adrél:
	gsub(/[-_a-z0-9]{2,64}@[-_a-z0-9]{2,64}\.[-_a-z0-9]{2,10}/, "<a href=\"mailto:&\">&</a>");
	# URL téléphone:
	gsub(/0[1-9]( [0-9][0-9]){4}/, "<a href=\"tel:+33&\">&</a>");
	while(match($0, /<a href="tel:\+330[0-9 .-]*"/))
	{
		url0 = substr($0, RSTART + 14, RLENGTH - 15);
		gsub(/[^0-9]/, ".", url0);
		url1 = url0;
		gsub(/\./, "", url1);
		sub(/^330/, "33", url1);
		url0 = "\\+"url0"\"";
		url1 = "+"url1"\"";
		gsub(url0, url1);
	}
	# URL MarkDown:
	while(match($0, /\[[^\[\]]*(\[[^\]]*\][^\[\]]*)*\]\([^)]*\)/))
	{
		lien = substr($0, (p = RSTART) + 1, (n = RLENGTH) - 2);
		match(lien, /\]\(/);
		libelle = substr(lien, 1, RSTART - 1);
		if(substr(lien, RSTART + 2, 9) == "<a href=\"")
		{
			lien = substr(lien, RSTART + 2);
			gsub("&", "\\\\&", libelle); # Le & a une signification particulière dans le remplacement, donc "Totor & Cie" doit devenir "Totor \& Cie" s'il sert de chaîne de remplacement.
			sub(/>[^<]*<\/a>$/, ">"libelle"</a>", lien);
		}
		else
			lien = "<a href=\""substr(lien, RSTART + 2)"\">"libelle"</a>";
		$0 = substr($0, 1, p - 1)lien""substr($0, p + n);
	}
}
{
	### Agrégation ###
	
	prec = prec$0;
}
END{
	affPrec(1);
	if(entete)
	{
	print "	</body>";
	print "</html>";
	}
}
