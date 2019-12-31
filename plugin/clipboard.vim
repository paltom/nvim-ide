nnoremap gy "+y
nnoremap gY "+Y
nnoremap gp "+p
nnoremap gP "+P
nnoremap gop o<esc>"+p
nnoremap gOp O<esc>"+p
inoremap <expr> <c-v> col('.') == 1 ? "\<esc>\"+gPi" : "\<esc>\"+gpi"
inoremap <c-g><c-v> <c-v>
vnoremap gy "+y
vnoremap gp "+p

