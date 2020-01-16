#!/bin/sh
# Copyright (c) 2020 Guillaume Outters
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

# Arbre des Processus
# Similaire au ps -faux Linux.
ap()
{
	LC_ALL=C ps axwwo user,pid,ppid,%cpu,%mem,vsz,rss,tt,stat,start,time,command | awk \
'
function faire(i, ind, numf) {
	if(ls[i])
	{
		aff = ls[i];
		if(match(aff, /^[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +/))
			aff = substr(aff, 1, RLENGTH)""ind""substr(aff, 1 + RLENGTH);
		print aff;
	}
	if(nfs[i])
	{
		gsub(/├ /, "│ ", ind);
		gsub(/└ /, "  ", ind);
		for(numf = 0; ++numf <= nfs[i];)
			faire(fs[i,numf], ind""(numf == nfs[i] ? "└ " : "├ "));
	}
}
NR==1{ print; next; }
{
	ls[$2] = $0;
	ps[$2] = $3;
	if($2 != $3)
		fs[$3,++nfs[$3]] = $2;
	else
		fs[$3,0] = $2;
}
END{
	for(p in nfs)
		if(!ps[p] || ps[p] == p)
			faire(p, "");
}
'
}
