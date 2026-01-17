" ln -s ~/src/scripts/vim/Notes.vim ~/.vim/syntax/
" /!\ Au préalable des règles pour les Notes.sql, Notes.sh
" echo 'au BufRead,BufNewFile Notes* set syntax=Notes' >> ~/.vimrc

if exists("b:current_syntax")
 finish
endif

syn match notesEnCours '^	*[=]\ze '
syn match notesTitre '^==.*'
syn match notesAFaire '^	*[-]\ze '
syn match notesTitre '^--.*'
syn match notesFini   '^	*[+*]\ze '
syn match notesAbandon   '^	*[*]\ze '
" À FAIRE: distinguer puces de titre: le titre est suivi et précédé d'une ligne vide (ou début de fichier), la puce non (autre puce, retour à la ligne ds la puce, retour à un para normal).
syn match notesNum       '^	*\([a-zA-Z]\|[IVX0-9]\+\)[.]\ze '
" À FAIRE: pas en erreur si déjà traité (+ ou *)
syn match notesAlerte    '/!\\'
syn match notesComm      '^#.*'
syn match notesUrl       'https*://[^ )]*'
" https://vi.stackexchange.com/a/22293 pour détecter sur une délimitation de mot autre que l'espace (qui était un peu facile: un espace jaune, ça ne se voyait pas trop).
" dans la même veine, https://vi.stackexchange.com/a/29547 pourrait un jour servir.
" https://stackoverflow.com/a/2462714/1346819
" https://vi.stackexchange.com/a/19130/45395
syn region notesImportant start="\(^\|[ '\]('\"]\)\*[^ ]"ms=e-1 end="\*\([ ,:;.?!\])\"']\|$\)"me=s oneline

" Cf. les couleurs dans syntax/syncolor.vim (merci https://askubuntu.com/questions/24544/what-is-the-default-vim-colorscheme#comment31987_24548)
hi def link notesTitre    Statement
hi def link notesAFaire   WarningMsg
hi def link notesEnCours  Statement
hi def link notesFini     MoreMsg
hi def link notesAbandon  Identifier
hi def link notesNum      Identifier
hi def link notesAlerte   ErrorMsg
hi def link notesComm     Identifier
hi def link notesImportant Gras
hi def link notesUrl      Gris

hi def Gras term=bold cterm=bold ctermfg=Yellow gui=bold
hi def Gris term=NONE cterm=NONE ctermfg=DarkGrey gui=NONE

" Le changement d'état d'une tâche est géré dans une fonction:
" 1. On mutualise
" 2. On évite de polluer l'historique de recherche par nos recherches techniques (cf. https://stackoverflow.com/a/1385213/1346819).
" Transcription en syntaxe nmap: $?^<C-V><TAB>*[-+=*]<SPACE><CR>/<SPACE><CR>hr (suivi du nouvel état).
function! Etat(etat)
	normal! $
	call search('^	*[-+=*⋅] ', 'b')
	call search(' ')
	exec 'normal hr' . a:etat
endfunction

" Alias F comme Fini (prendre une tâche et la caler dans les Terminées, puis retour).

:map F $/^[^<C-V><TAB> ]<CR>mek$md?^[^<C-V><TAB> ]<CR>:s/^\([*]\)\?/\1+/<CR>:s/^\([+*]\)./\1/<CR>d'd/^[+*]<CR>?^$<CR>p'e
:map - :call Etat("-")<CR>
" À FAIRE: au lieu de requérir un --, se caler dans le - si on a déjà un - en début de ligne.
" À FAIRE: -- pour ajouter une ligne -
" À FAIRE?: dater systématiquement les nouvelles lignes?
:map -- -A {}<ESC>"=strftime('%Y-%m-%d')<CR>P
:map = :call Etat("=")<CR>
:map + :call Etat("+")<CR>
:map ++ +A []<ESC>"=strftime('%Y-%m-%d')<CR>P
:map +++ ++a<SPACE>
:map * :call Etat("*")<CR>
:map ** *A []<ESC>"=strftime('%Y-%m-%d')<CR>P
:map *** **a<SPACE>
:map ⋅ :call Etat("⋅")<CR>

" À FAIRE: ancres [#hips] auxquelles on peut référer via cf. #hips ou après #hips
