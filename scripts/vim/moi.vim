" Utilisation: dans le .vimrc:
"   " Au moins une expression.
"   let g:lesmiens =<< FINI
"   /src/
"   FINI
"   let g:lesautres =<< trim FINI
"   /src/projets/(ng*|doctrine*|orme/src/Doctrine)/
"   FINI
"   source ~/src/scripts/vim/moi.vim
"   autocmd BufRead,BufNewFile * call ChezNous()
"   autocmd FileType sh call ChezMoi()

let g:lesmiens = join(map(g:lesmiens, 'substitute(substitute(v:val, "[(|).]", "\\\\&", "g"), "\*", ".*", "g")'), '\|')
let g:lesautres = join(map(g:lesautres, 'substitute(substitute(v:val, "[(|).]", "\\\\&", "g"), "\*", ".*", "g")'), '\|')

function ChezMoi()
	" setlocal, <buffer>: https://stackoverflow.com/a/8826323/1346819
	setlocal noexpandtab
	setlocal nosmarttab
	
	" Vieille ruse inspirée de <http://www.vmunix.com/vim/answ.html> pour ne pas
	" laisser au formateur automatique transformer toute première ligne blanche en
	" ligne vide (suppression de l'indentation): on filtre les caractères retour
	" pour les délivrer sous forme du retour suivi d'un X immédiatement effacé.
	" Ainsi le formateur ne reçoit pas de suite les deux retours qu'il attend de
	" pied ferme.
	" À FAIRE: ça doit pouvoir se configurer, un formateur, non?
	inoremap <buffer> <C-M> <C-M>X<C-H>
	nnoremap <buffer> o oX<C-H>
	nnoremap <buffer> O OX<C-H>
endfunction

function ChezNous()
	" https://vi.stackexchange.com/a/2741
	if expand('%:p') =~ g:lesmiens && expand('%:p') !~ g:lesautres
		call ChezMoi()
	endif
endfunction
