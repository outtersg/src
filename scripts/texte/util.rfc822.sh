# Copyright (c) 2026 Guillaume Outters
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

# Lit un message RFC822, passant chaque PJ à une fonction passée en paramètre.
# Utilisation: rfc822_pjs <test> < <fichier>
#   <test>
#     Test (écrit en awk) invoqué lors du passage des en-têtes au corps de bloc MIME;
#     si le test est positif (on souhaite récupérer cette PJ), doit mettre dans la variable dest un chemin vers lequel écrire le fichier.
rfc822_pjs()
{
	local test="$1"
	awk \
	'
		# etat:
		#   0: corps de texte
		#   1: 1 ligne vide
		#   2: 1 ligne vide, une ligne -- (début de segment MIME)
		#   3: en-têtes
		BEGIN { partie = 0; etat = 3; }
		function fermer() {
			if(cumul) { cumul = substr(cumul, 1, length(cumul) - 1); pousser(cumul); cumul = ""; }
			if(dest)
				if(decodage)
					close(decodage);
				else
					close(dest);
		}
		function pousser(x) {
			if(!dest) return;
			if(decodage)
				print x | decodage;
			else
				print x > dest;
		}
		function finirEnTete() {
			if(!accuEnTete) return;
			match(accuEnTete, /: /);
			enTetes[substr(accuEnTete, 1, RSTART - 1)] = substr(accuEnTete, RSTART + 2);
			accuEnTete = "";
		}
		/^--/ && etat <= 1 { etat = 2; } # À FAIRE: il peut y avoir des -- qui ne correspondent pas au délimiteur annoncé au départ, à considérer comme du texte brut sans changement d état.
		/^$/ {
			if(etat == 3)
			{
				finirEnTete();
				etat = 0;
				dest = "";
				'"$test"'
				if(dest)
				{
					if(enTetes["Content-Transfer-Encoding"] == "base64")
						decodage = "'"$HOME/bin/debase64"'";
					else
					{
						print "# Erreur: je devrais pondre vers "dest" avec un Content-Transfer-Encoding de "enTetes["Content-Transfer-Encoding"] > "/dev/stderr";
						dest = "";
						decodage = "";
					}
					if(dest && decodage)
						decodage = decodage" > "dest;
				}
			}
			else
				etat = 1;
		}
		etat == 0 && dest {
			pousser($0);
		}
		etat > 0 && etat < 2 { cumul = cumul$0"\n"; }
		etat == 2 && /: / { ++etat; delete enTetes; fermer(); accuEnTete = ""; }
		etat == 3 {
			if($0 ~ /^[^ 	][^:]*: /)
			{
				finirEnTete();
				accuEnTete = $0;
			}
			else
			{
				sub(/^	/, " "); sub(/^ 	/, "		"); # Uniformisation: une tabulation = espace (mais plusieurs tabulations sont préservées).
				accuEnTete = accuEnTete$0;
			}
		}
		END { if(dest) fermer(); }
	'
}
