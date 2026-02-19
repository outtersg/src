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
}
function affPrec(fin){
	if(!match($0, /./) && !fin)
	{
		++lignevide;
		return;
	}
	
	if(niv > 0)
		prec = prec"</li>";
	else if(!para && !fin)
		# À FAIRE?: les <p>? Mais ils me font chier avec leurs marges entre <p> et <ul> et compagnie.
		prec = prec""(lignevide ? "<br/>" : "")"<br/>";
	for(i = niv; --i >= prochniv;)
		prec = prec"</ul>";
	
	print prec;
	prec = "";
	
	if(prochniv > 0)
	{
		if((puce = puces[puce]))
			puce = " class=\""puce"\"";
		prec = "<li"puce">"prec;
	}
	if(prochniv > niv)
		prec = "<ul>"prec;
	
	niv = prochniv;
	prochniv = 0;
	lignevide = 0;
	if(para) --para;
}
# À FAIRE: ne pas oublier l'indentation à 3 espaces ou plus après un 123.
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
# Façon LDAP, une ligne commençant par l'indentation mais sans tirets est la continuité du tiret.
niv && /^\t*[^-+*=•\t]/{
	match($0, /^\t* */);
	if(RLENGTH >= niv)
	{
		prec = prec"<br/>"substr($0, niv);
		next;
	}
}
# À FAIRE: ne doit-on pas traiter les < > & */
/^\t*[-+*=•] /{
	match($0, /^\t*[^\t]/);
	puce = substr($0, RLENGTH, 1);
	prochniv = RLENGTH;
	$0 = substr($0, RLENGTH + 2);
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
{
	### Retravail ###
	
	# URL sèches:
	# Expression de reconnaissance des URL: à synchroniser avec Notes.vim.
	gsub(/https*:\/\/[^ ),;]*/, "<a href=\"&\">&</a>");
	# URL téléphone:
	gsub(/0[1-9]( [0-9][0-9]){4}/, "<a href=\"tel:+33&\">&</a>");
	while(match($0, /<a href="tel:\+330[1-9 .-]*"/))
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
			sub(/>[^<]*<\/a>$/, ">"libelle"</a>", lien);
		}
		else
			lien = "<a href=\""substr(lien, RSTART + 2)"\">"libelle"</a>";
		$0 = substr($0, 1, p - 1)lien""substr($0, p + n);
	}
	
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
