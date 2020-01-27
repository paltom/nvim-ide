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

 " NOT TESTED
function! s:get_hi_color(group_name, attribute) abort
  let l:highlight_group = execute("highlight ".a:group_name)
  let l:attributes = filter(split(l:highlight_group), 'v:val =~ "="')
  let l:color = filter(map(l:attributes, 'split(v:val, "=")'), 'v:val[0] == "'.a:attribute.'"')[0][1]
  return l:color
endfunction
let s:stl_bg = s:get_hi_color("StatusLine", "guibg")
execute "highlight STLWarning guibg=".s:stl_bg." guifg=".s:get_hi_color("ALEWarningSign", "guifg")
execute "highlight STLLocation guifg=".s:stl_bg." guibg=".s:get_hi_color("StatusLine", "guifg")
execute "highlight STLCWD guifg=".s:get_hi_color("String", "guifg")." gui=inverse"
function! s:highlight_stl_part(part, highlight_group)
  return "%#".a:highlight_group."#".a:part."%#StatusLine#"
endfunction

let s:stl_sep = " "
function! s:stl_cwd()
  return "%{pathshorten(fnamemodify(getcwd(), ':~'))}:"
endfunction
function! s:stl_file_info()
  " Group %(%) is needed for correct field size when flags are empty
  " :help 'statusline'
  let l:flags = "%-3.3(%{&modifiable && !&readonly ? (&modified ? ' \u274b ' : '___') : '\U1f512 '}%)"
  let l:trunc = "%<"
  let l:path_disabled_ft = ['help']
  if index(l:path_disabled_ft, &filetype) >= 0
    let l:filename = "%{expand('%:t')}"
  else
    let l:filename = "%{expand('%') == '' ? '[No Name]' : pathshorten(expand('%:.:h')).expand('/').expand('%:t')}"
  endif
  return s:highlight_stl_part(l:flags, "STLWarning").l:trunc.l:filename.s:stl_sep
endfunction
function! s:stl_type()
  return "%(%y%q%w%)"
endfunction
function! s:stl_location()
  let l:curline = getcurpos()[1]
  let l:file_lines = line("$")
  let l:block_nr = float2nr(floor((l:curline-1)/0.111111/l:file_lines))
  let l:blocks = ["\u2588", "\u2587", "\u2586", "\u2585", "\u2584", "\u2583", "\u2582", "\u2581", " "]
  return l:blocks[l:block_nr]
endfunction
function! s:stl_win_id()
  return "[%{winnr()}]"
endfunction

function! Stl()
  let l:stl = ""
  let l:stl .= s:highlight_stl_part(s:stl_cwd(), "STLCWD")
  let l:stl .= s:stl_file_info()
  let l:stl .= "%="
  let l:stl .= s:stl_type()
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_location(), "STLLocation")
  let l:stl .= s:stl_sep
  let l:stl .= s:stl_win_id()
  return l:stl
endfunction

set statusline=%!Stl()
