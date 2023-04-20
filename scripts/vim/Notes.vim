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

" Cf. les couleurs dans syntax/syncolor.vim (merci https://askubuntu.com/questions/24544/what-is-the-default-vim-colorscheme#comment31987_24548)
hi def link notesTitre    Statement
hi def link notesAFaire   WarningMsg
hi def link notesEnCours  Statement
hi def link notesFini     MoreMsg
hi def link notesAbandon  Identifier

" Alias F comme Fini (prendre une tâche et la caler dans les Terminées, puis retour).

:map F $/^[^<C-V><TAB> ]<CR>mek$md?^[^<C-V><TAB> ]<CR>r+d'd/^+<CR>?^$<CR>p'e
:map - $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr-
:map = $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr=
:map + $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr+
:map * $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr*
