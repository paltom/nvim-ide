let s:colorscheme_plugin = "vim-one"

" Load guard for one-time loading of plugins (colorscheme)
"if exists("g:loaded_visuals")
  "finish
"endif
"let g:loaded_visuals = 1

let g:one_allow_italics = 1
set termguicolors
set background=dark
call ext#plugins#load([s:colorscheme_plugin])
colorscheme one

set scrolloff=3

set number relativenumber numberwidth=5

let &listchars = "tab:\u00bb ,trail:\u2423"
set list
set nowrap sidescroll=35
let &listchars .= ",precedes:\u27ea,extends:\u27eb"

highlight! link Folded FoldColumn
highlight! link VertSplit StatusLineNC
let &fillchars = "vert: "

function! VisualPercentage()
  let l:curline = getcurpos()[1]
  let l:file_lines = line("$")
  let l:block_nr = float2nr(floor((l:curline-1)/0.111111/l:file_lines))
  let l:blocks = ["\u2588", "\u2587", "\u2586", "\u2585", "\u2584", "\u2583", "\u2582", "\u2581", " "]
  return l:blocks[l:block_nr]
endfunction

set statusline=%3.3(%{&modifiable&&!&readonly?\(&modified?'\ *\ ':''\):'\ -\ '}%)%<%{expand('%')==''?'[No\ Name]':pathshorten(expand('%:~:h')).expand('/').expand('%:t')}%=%(%y%q%w%)\ %#TermCursor#%{VisualPercentage()}%#Statusline#\ [%{winnr()}]
