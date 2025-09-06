BEGIN{
	niv = 0;
	prochniv = 0;
	lignevide = 0;
	para = 0;
	while(getline <"/home/gui/src/scripts/texte/notes2html.html")
		print;
	puces["-"] = "lim";
	puces["+"] = "lip";
	puces["="] = "lieg";
	puces["*"] = "liet";
}
function affPrec(){
	if(!match($0, /./))
	{
		++lignevide;
		return;
	}
	
	if(niv > 0)
		prec = prec"</li>";
	else if(!para)
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
# Façon LDAP, une ligne commençant par l'indentation mais sans tirets est la continuité du tiret.
niv && /^\t*[^-+*=\t]/{
	match($0, /^\t*/);
	if(RLENGTH >= niv - 1)
	{
		prec = prec"<br/>"substr($0, niv);
		next;
	}
}
/^\t*[-+*=] /{
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
{ affPrec(); }
/^$/{ ++lignevide; }
/./ { lignevide = 0; }
{ prec = prec$0; }
END{
	affPrec();
	print "	</body>";
	print "</html>";
}
