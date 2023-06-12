#!/bin/sh
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

function auSecours()
{
	print "# lotir" > "/dev/fd/2"
	print "# Répartit les lignes en entrée sur plusieurs fichiers en sortie" > "/dev/fd/2"
	print "# © Guillaume Outters 2023" > "/dev/fd/2"
	print "" > "/dev/fd/2"
	print "Utilisation: lotir <n lots> <chemin de sortie> [--prologue <prologue>] [--epilogue <épilogue>] [<gabarit ligne>*]" > "/dev/fd/2"
	print "  <n lots>" > "/dev/fd/2"
	print "    Entier (>= 2 pour avoir un intérêt)" > "/dev/fd/2"
	print "  <chemin de sortie>" > "/dev/fd/2"
	print "    Chemin des fichiers de sortie; le \%d sera remplacé par un nombre de la plage [0;<n lots>[" > "/dev/fd/2"
	print "  --prologue <prologue>"
	print "    Ligne à ajouter en début de chaque fichier pondu" > "/dev/fd/2"
	print "  <gabarit ligne>" > "/dev/fd/2"
	print "    Si mentionné, les lignes ne seront pas réparties telles quelles, mais incluses dans un gabarit (devant contenir un \%s qui sera remplacé par la ligne)" > "/dev/fd/2"
	print "    Si plusieurs <gabarit ligne> se suivent, chaque ligne d'entrée donnera lieu à autant de lignes en sortie qu'en comporte le gabarit." > "/dev/fd/2"
	print "  --epilogue <épilogue>"
	print "    Ligne à ajouter en fin de chaque fichier pondu" > "/dev/fd/2"
	exit(1);
}
BEGIN{
	N_LOTS = 0;
	GABARIT_SORTIES = "";
	GL_N = 0;
	gl_a_rempl = 0;
	PROLOGUE = "";
	EPILOGUE = "";
	
	for(i = 0; ++i < ARGC;)
	{
		if(ARGV[i] == "--prologue") { delete ARGV[i]; PROLOGUE = ARGV[++i]; }
		else if(ARGV[i] == "--epilogue") { delete ARGV[i]; EPILOGUE = ARGV[++i]; }
		else
		{
			if(!N_LOTS)
			{
				if(!(N_LOTS = 0 + ARGV[i]))
				{
					print "# Le nombre de lots doit être un entier positif." > "/dev/fd/2"
					exit(1);
				}
			}
			else if(!GABARIT_SORTIES)
			{
				if((GABARIT_SORTIES = ARGV[i]) !~ /%[0-9.]*d/)
				{
					print "# Le gabarit de fichier de sortie doit prévoir un numéro de fichier sous la forme %d" > "/dev/fd/2"
					exit(1);
				}
			}
			else
			{
				GABARIT_LIGNES[GL_N++] = ARGV[i];
				if(!gl_a_rempl) gl_a_rempl = ARGV[i] ~ /%s/;
			}
		}
		delete ARGV[i];
	}
	
	if(!N_LOTS || !GABARIT_SORTIES)
		auSecours();
	if(GL_N < 1)
		GABARIT_LIGNES[GL_N++] = "%s";
	else if(!gl_a_rempl)
	{
		print "# Le gabarit des lignes doit prévoir l'insertion de la source sous la forme %s" > "/dev/fd/2"
		exit(1);
	}
	for(i = -1; ++i < N_LOTS;)
		SORTIES[i] = sprintf(GABARIT_SORTIES, i);
}
NR<=N_LOTS&&PROLOGUE{
	print PROLOGUE > SORTIES[NR - 1];
}
{
	for(i = -1; ++i < GL_N;)
		print sprintf(GABARIT_LIGNES[i], $0) > SORTIES[(NR - 1) % N_LOTS];
}
END{
	if(EPILOGUE)
		for(i = N_LOTS > NR ? NR : N_LOTS; --i >= 0;)
			print EPILOGUE > SORTIES[i];
}
