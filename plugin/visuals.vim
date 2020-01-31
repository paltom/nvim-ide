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
execute "highlight STLFlags guibg=".s:stl_bg." guifg=".s:get_hi_color("ALEWarningSign", "guifg")
execute "highlight STLLocation guifg=".s:stl_bg." guibg=".s:get_hi_color("StatusLine", "guifg")
execute "highlight STLCWD guifg=".s:get_hi_color("String", "guifg")." gui=inverse"
execute "highlight! link STLEmpty StatusLineNC"
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
  if &modifiable && !&readonly
    if &modified
      let l:flag = " \u274b"
    else
      let l:flag = ""
    endif
  else
    let l:flag = "\U1f512"
  endif
  if empty(l:flag)
    let l:flags = "   "
  else
    let l:flags = s:highlight_stl_part(l:flag, "STLFlags").s:stl_sep
  endif
  let l:trunc = "%<"
  let l:path_disabled_ft = ['help']
  if index(l:path_disabled_ft, &filetype) >= 0
    let l:filename = "%{expand('%:t')}"
  else
    let l:filename = "%{expand('%') == '' ? '[No Name]' : pathshorten(expand('%:.:h')).expand('/').expand('%:t')}"
  endif
  return l:flags.l:trunc.l:filename.s:stl_sep
endfunction
function! s:stl_type()
  return "%(%y%q%w%)"
endfunction
function! s:stl_location()
  let l:curline = getcurpos()[1]
  let l:file_lines = line("$")
  let l:block_nr = float2nr(floor((l:curline-1)/0.111111/l:file_lines)) " 0.111111 = 1/9
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
  let l:stl .= s:highlight_stl_part("%=", "STLEmpty")
  let l:stl .= s:stl_sep
  let l:stl .= s:stl_type()
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_location(), "STLLocation")
  let l:stl .= s:stl_sep
  let l:stl .= s:stl_win_id()
  return l:stl
endfunction

function! StlNC()
  let l:stl = ""
  let l:stl .= s:stl_file_info()
  return l:stl
endfunction

setlocal statusline=%!Stl()
augroup statusline_update
  autocmd!
  autocmd WinEnter * for n in range(1, winnr('$'))|if n == winnr()|call setwinvar(n, '&statusline', '%!Stl()')|else|call setwinvar(n, '&statusline', '%!StlNC()')|endif|endfor
augroup end
