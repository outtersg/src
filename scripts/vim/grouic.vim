" ln -s ~/src/scripts/vim/grouic.vim ~/.vim/syntax/
" echo 'au BufRead,BufNewFile *.grouic set syntax=grouic' >> ~/.vimrc

if exists("b:current_syntax")
 finish
endif

syn match diffComment '^#.*'
syn match diffRemoved '^[xX] [^[xX]*\[[^]]*\]'
syn match diffAdded   '^  *[xX][^[]*\[[^]]*\]'

" Commentaire en NonText plutôt que Comment, ce dernier ayant tendance à adopter le vert qui se confond avec diffAdded.
hi def link diffComment	NonText
hi def link diffRemoved	WarningMsg
hi def link diffAdded   MoreMsg
