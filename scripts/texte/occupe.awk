# Copyright (c) 2025 Guillaume Outters
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

# OCCUPE
# Outters' C Clean and Unencumbered PreProcessor for Exactness
# A cpp replacement for when your usual constipated preprocessor occupies the place.

function err(message)
{
	print "[31m# "message"[0m" > "/dev/stderr";
	exit(1);
}
function calcglobal()
{
	global = 1;
	for(i = niveau + 1; --i > 0;)
		if(!niveaux[i])
		{
			global = 0;
			return;
		}
}
BEGIN {
	niveau = 0;
	global = 1; # On affiche, tant qu'on n'entre pas dans un #if 0
	for(i = 0; ++i < ARGC;)
		# Pour être compatibles cpp il nous faudrait du -DVAR=VAL, mais awk n'aime pas trop les options commençant par -, on propose aussi les =DVAR=VAL ou VAR=VAL ou =-DVAR=VAL
		if(ARGV[i] ~ /^[-=]+D/ || ARGV[i] ~ /^[A-Za-z0-9_]+=/)
		{
			var = ARGV[i];
			sub(/^[-=]+D/, "", var);
			val = 1;
			if(match(var, "="))
			{
				val = substr(var, RSTART + 1);
				var = substr(var, 1, RSTART - 1);
			}
			vars[var] = val;
			delete ARGV[i];
		}
}
/^[ \t]*#/ {
	if($1 == "#endif")
	{
		if(niveau == 0)
		{
			err("Balise fermée non ouverte, "NR);
			exit(1);
		}
		--niveau;
		# Si on était en #if 0, on regarde si en sortir nous permet de passer en #if 1.
		if(!global && niveaux[niveau + 1] <= 0)
			calcglobal();
	}
	else
	{
		if($1 == "#else" || ($1 == "#elif" && niveaux[niveau] == 1)) # Un #elif, si le #if le précédent a déjà eu lieu, fait plouf tout comme un #else.
		{
			if(!niveau)
				err("#else sans #if, l. "NR);
			if(niveaux[niveau]) # Si on était en cours de #if valide (1), ou déjà consommé (-1), on reste dans ce dernier état.
			{
				niveaux[niveau] = -1;
				global = 0;
			}
			else # #if encore jamais consommé, le #else est donc bon.
			{
				niveaux[niveau] = 1;
				calcglobal();
			}
		}
		else if($1 == "#if" || $1 == "#elif")
		{
			# Évaluation de la condition, assez sommaire pour le moment: si la variable est définie et non nulle.
			if($1 == "#if") ++niveau;
			niveaux[niveau] = vars[$2];
			if(global == !niveaux[niveau])
				if(global)
					global = 0;
				else
					calcglobal();
		}
		else
			err("Connais pas le mot-clé "$0" (l. "NR")");
	}
	next;
}
global { print; }
END {
	if(niveau)
		# À FAIRE: avoir un tableau des ouvertures pour désigner la ligne couplable.
		err("Balises non fermées.");
}
