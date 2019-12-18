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

nnoremap <silent> ]s :silent! cnext<cr>
nnoremap <silent> [s :silent! cprevious<cr>
