" Collage d'une ligne de résumé d'offre d'emploi LinkedIn (générée par ../reseau/linkedin.user.js)
" au bon endroit dans une liste de type Notes.vim (une première ligne - LinkedIn, puis des items par offre, en ordre décroissant de numéro d'offre).

function! OffreLinkedIn()
	let li = trim(@+)
	let id = substitute(substitute(li, '.*http[^ ]*[/=]', '', ''), '[^0-9].*', '', '')
	let rech = id
	let suffixe = ''
	while len(id) > 3
		let chiffre = id % 10 - 1
		let id = id / 10
		if chiffre >= 0
			let rech = rech.'\|'.id.(chiffre ? '[0-'.chiffre.']' : '0').suffixe
		endif
		let suffixe = suffixe.'[0-9]'
	endwhile
	0
	call search('^. LinkedIn')
	call search(rech)
	" https://vi.stackexchange.com/questions/12445/how-can-i-append-text-to-the-current-line
	call append(line('.') - 1, "\t".li)
	exe ':normal! O  '
endfunction

:map <C-B> :call OffreLinkedIn()<CR>a
:imap <C-B> <ESC>:call OffreLinkedIn()<CR>a
