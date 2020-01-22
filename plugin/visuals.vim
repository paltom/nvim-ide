let s:colorscheme_plugin = "vim-one"

" Load guard for one-time loading of plugins (colorscheme)
"if exists("g:loaded_visuals")
  "finish
"endif
"let g:loaded_visuals = 1

let g:one_allow_italics = 1
set termguicolors
call ext#plugins#load([s:colorscheme_plugin])
colorscheme one

set scrolloff=3

set number relativenumber numberwidth=5

let &listchars = "tab:\u00bb ,trail:\u2423"
set list
set nowrap sidescroll=35
let &listchars .= ",precedes:\u27ea,extends:\u27eb"
