:let ladate = strftime("%d/%m/%y")
:let lemagasin = "CO"
:imap <F3> <ESC>G?
:map <F3> Yp0c2t<TAB><C-R>=ladate<CR><TAB>"<C-R>=lemagasin<CR>"<ESC>/<TAB><C-M>nnC<TAB>
:imap [13~ <ESC>G?
:map [13~ Yp0c2t<TAB><C-R>=ladate<CR><TAB>"<C-R>=lemagasin<CR>"<ESC>/<TAB><C-M>nnC<TAB>
:se nowrap
:se noexpandtab
