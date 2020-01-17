let s:colorscheme_plugin = "vim-one"

if exists("g:loaded_visuals")
  finish
endif
let g:loaded_visuals = 1

let g:one_allow_italics = 1
set termguicolors
call ext#plugins#load([s:colorscheme_plugin])
colorscheme one

set scrolloff=3

set number relativenumber numberwidth=5

let &listchars = "tab:\u00bb "
set list
