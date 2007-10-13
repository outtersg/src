" Rajoute une commande NP permettant de mettre dans un registre "pui" son
" argument n, puis branche sur la touche F4 une fonction qui insère un espace à
" l'abcisse courante dans les n lignes au-dessus.
" L'idée est de pouvoir éditer un fichier où il faut aligner les mots sur n
" lignes consécutives, les n - 1 premières l'étant déjà. On se place alors sur
" la nième, et l'on insère, selon que c'est elle qui a du retard sur les
" précédentes ou l'inverse, des espaces ou des F4.

" Problème: ce crétin de vim s'embrouille avec de l'UTF-8, entre les numéros de
" colonne. Le seul moyen pour que ça marche est de simuler la manip à la main,
" là il ne se plante pas. Autrement dit, passer par un :imap. Sauf que voilà,
" celui-ci ne sait pas boucler. On fait donc un imap qui appelle une fonction
" qui définit un imap avec le bon nombre de boucles puis sort, et l'imap
" appelant appelle alors l'imap tout juste créé. Merci les fonctions de ne pas
" me permettre de simuler une saisie!

:function! RamenePrecedentes()
	let c = col(".")
	let n2 = getreg("pui")
	while n2 < line(".")
		let l = getline(n2)
		call setline(n2, strpart(l, 0, c)." ".strpart(l, c))
		let n2 = n2 + 1
	endwhile
	call cursor(line("."), c + 1)
endfunction
:function! RetenirDebutPrecedentes()
	:call setreg("pui", line("."))
endfunction
:function! DefinirRamenagePrecedentes()
	let c = ":map <F12> i"
	let n2 = getreg("pui")
	while n2 < line(".")
		let c = c."<UP> <LEFT>"
		let n2 = n2 + 1
	endwhile
	let n2 = getreg("pui")
	while n2 < line(".")
		let c = c."<DOWN>"
		let n2 = n2 + 1
	endwhile
	exe c."<RIGHT>"
endfunction
:imap <F4> <ESC>:call RamenePrecedentes()<CR>i
:imap <F4> <RIGHT><ESC>:call DefinirRamenagePrecedentes()<CR><F12>
:imap <F3> <ESC>:call RetenirDebutPrecedentes()<CR>a
:map <F3> :call RetenirDebutPrecedentes()<CR>i
:se nowrap
