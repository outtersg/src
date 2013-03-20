:let ladate = strftime("%y/%m/%d")
:let lemagasin = "CO"
:imap <F3> <ESC>G?
:map <F3> Yp0c2t<TAB><C-R>=ladate<CR><TAB>"<C-R>=lemagasin<CR>"<ESC>/<TAB><C-M>nnC<TAB>
:se nowrap
