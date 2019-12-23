nnoremap <a-h> <c-w>h
nnoremap <a-j> <c-w>j
nnoremap <a-k> <c-w>k
nnoremap <a-l> <c-w>l
inoremap <a-h> <c-\><c-N><c-w>h
inoremap <a-j> <c-\><c-N><c-w>j
inoremap <a-k> <c-\><c-N><c-w>k
inoremap <a-l> <c-\><c-N><c-w>l
vnoremap <a-h> <c-w>h
vnoremap <a-j> <c-w>j
vnoremap <a-k> <c-w>k
vnoremap <a-l> <c-w>l
tnoremap <a-h> <c-\><c-N><c-w>h
tnoremap <a-j> <c-\><c-N><c-w>j
tnoremap <a-k> <c-\><c-N><c-w>k
tnoremap <a-l> <c-\><c-N><c-w>l
tnoremap <c-w> <c-\><c-n>

noremap H ^
noremap L $

nnoremap <silent> [t :tabprevious<cr>
nnoremap <silent> ]t :tabnext<cr>
nnoremap <silent> <c-t>t :tabnext<cr>
nnoremap <silent> <c-t><c-t> :tabnext<cr>

nnoremap <silent> ]s :if len(getloclist(0)) > 0\|lnext\|else\|cnext\|endif<cr>
nnoremap <silent> [s :if len(getloclist(0)) > 0\|lprevious\|else\|cprevious\|endif<cr>

inoremap <c-j> <c-n>
inoremap <c-k> <c-p>

if has("nvim-0.4.2")
  set wildcharm=<tab>
  cnoremap <expr> <left>  wildmenumode() ? "\<up>"    : "\<left>"
  cnoremap <expr> <right> wildmenumode() ? "\<down>"  : "\<right>"
  cnoremap <expr> <up>    wildmenumode() ? "\<left>"  : "\<up>"
  cnoremap <expr> <down>  wildmenumode() ? "\<right>" : "\<down>"
  cnoremap <expr> <c-h>   wildmenumode() ? "\<up>"    : "\<c-h>"
  cnoremap <expr> <c-l>   wildmenumode() ? "\<down>"  : "\<c-l>"
  cnoremap <expr> <c-k>   wildmenumode() ? "\<left>"  : "\<c-k>"
  cnoremap <expr> <c-j>   wildmenumode() ? "\<right>" : "\<c-j>"
endif
