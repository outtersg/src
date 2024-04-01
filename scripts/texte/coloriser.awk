# Copyright (c) 2023 Guillaume Outters
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# awk -f ~/src/scripts/texte/coloriser.awk -- -k <colonne à surveiller> "<seuil rouge> <seuil orange> <seuil vert>" /tmp/x.csv
# Ex. pour coloriser en vert les lignes commençant par un pourcentage inférieur à 10 %, en rouge celles dépassant les 80 %, et passant de l'un à l'autre avec un orange à 50 %:
# awk -f ~/src/scripts/texte/coloriser.awk -- "80 50 10" /tmp/x.csv

BEGIN{
	col = 1;
	FS = "\t";
	for(i = 0; ++i <= ARGC;)
	{
		if(ARGV[i] == "-k")
		{
			delete ARGV[i]; col = ARGV[++i]; delete ARGV[i];
		}
		else if(!seuils[1])
		{
			split(ARGV[i], seuils, / +/);
			delete ARGV[i];
		}
	}
	print "<style type=\"text/css\">table, th, tr, td { border-collapse: collapse; border: 1px solid #bfbfbf; } th, td { padding: 0 .2em 0 .2em; }</style>";
	print "<table style=\"border-collapse: collapse; border: 1px solid gray;\">";
	
	couleurs = "255 0 0 ; 255 127 0 ; 191 191 0 ; 0 191 0";
	gsub(/ *; */, ";", couleurs);
	split(couleurs, couls, /;/);
}
function coul(val){
	sub(/\./, ",", val); # Pour moi qui travaille en locale française.
	val = 0 + val;
	entre = et = 1;
	for(i = 0; ++i <= 4;)
	{
		if(val >= seuils[i])
			break;
		entre = et;
		if(i < 4) ++et;
	}
	if(entre == et)
		pos = 1;
	else
		pos = (val - seuils[entre]) / (seuils[et] - seuils[entre]);
	
	split(couls[entre], centre, / +/);
	split(couls[et], cet, / +/);
	res = "";
	for(i = 0; ++i <= 3;)
		res = res""sprintf("%02.2x", pos * (0 + cet[i]) + (1 - pos) * (0 + centre[i]));
	return res;
}
{
	tc = NR == 1 ? "th" : "td";
	printf("<tr>");
	for(i = 0; ++i <= NF;)
		printf("<%s%s>%s</%s>", tc, i == col && NR > 1 ? " style=\"color: #"coul($col)"\"" : "", $i, tc);
	printf("</tr>\n");
}
END{
	print "</table>";
}
