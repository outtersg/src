" ln -s ~/src/scripts/vim/Notes.vim ~/.vim/syntax/
" /!\ Au préalable des règles pour les Notes.sql, Notes.sh
" echo 'au BufRead,BufNewFile Notes* set syntax=Notes' >> ~/.vimrc

if exists("b:current_syntax")
 finish
endif

syn match notesEnCours '^	*[=]'
syn match notesTitre '^==.*'
syn match notesAFaire '^	*[-]'
syn match notesTitre '^--.*'
syn match notesFini   '^	*[+*]'
syn match notesAbandon   '^	*[*]'
" À FAIRE: pas en erreur si déjà traité (+ ou *)
syn match notesAlerte    '/!\\'
syn match notesComm      '^#.*'
" https://vi.stackexchange.com/a/22293 pour détecter sur une délimitation de mot autre que l'espace (qui était un peu facile: un espace jaune, ça ne se voyait pas trop).
" dans la même veine, https://vi.stackexchange.com/a/29547 pourrait un jour servir.
syn region notesImportant start="[ '\]]\*"ms=e end="\*[ ,;.?!\]]"me=s

" Cf. les couleurs dans syntax/syncolor.vim (merci https://askubuntu.com/questions/24544/what-is-the-default-vim-colorscheme#comment31987_24548)
hi def link notesTitre    Statement
hi def link notesAFaire   WarningMsg
hi def link notesEnCours  Statement
hi def link notesFini     MoreMsg
hi def link notesAbandon  Identifier
hi def link notesAlerte   ErrorMsg
hi def link notesComm     Identifier
hi def link notesImportant Gras

hi def Gras term=bold cterm=bold ctermfg=Yellow gui=bold

" Alias F comme Fini (prendre une tâche et la caler dans les Terminées, puis retour).

:map F $/^[^<C-V><TAB> ]<CR>mek$md?^[^<C-V><TAB> ]<CR>r+d'd/^+<CR>?^$<CR>p'e
:map - $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr-
:map = $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr=
:map + $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr+
:map ++ +A []<ESC>"=strftime('%Y-%m-%d')<CR>P
:map +++ ++a<SPACE>
:map * $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr*
