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
set nowrap sidescroll=1 sidescrolloff=10
let &listchars .= ",precedes:\u27ea,extends:\u27eb"

highlight! link Folded FoldColumn
highlight! link VertSplit StatusLineNC
let &fillchars = "vert: "

function! s:get_hi_color(group_name, attribute) abort
  let l:highlight_group = execute("highlight ".a:group_name)
  let l:attributes = filter(split(l:highlight_group), 'v:val =~ "="')
  let l:color = filter(map(l:attributes, 'split(v:val, "=")'), 'v:val[0] == "'.a:attribute.'"')[0][1]
  return l:color
endfunction
let s:stl_bg = s:get_hi_color("StatusLine", "guibg")
execute "highlight STLFlags guibg=".s:stl_bg." guifg=".s:get_hi_color("ALEWarningSign", "guifg")
execute "highlight STLLocation guifg=".s:stl_bg." guibg=".s:get_hi_color("Directory", "guifg")
execute "highlight STLCWD guifg=".s:get_hi_color("String", "guifg")." gui=inverse,bold"
execute "highlight! link STLEmpty TermCursor"
execute "highlight STLWinnr gui=bold"
function! s:highlight_stl_part(part, highlight_group)
  return "%#".a:highlight_group."#".a:part."%#StatusLine#"
endfunction

let s:stl_sep = " "
function! s:stl_cwd()
  return "%{pathshorten(fnamemodify(getcwd(), ':~'))}:"
endfunction

function! s:stl_file_flags(winnr)
  let l:bufnr = winbufnr(a:winnr)
  let l:modifiable = getbufvar(l:bufnr, '&modifiable')
  let l:readonly = getbufvar(l:bufnr, '&readonly')
  if l:modifiable && !l:readonly
    let l:modified = getbufvar(l:bufnr, '&modified')
    if l:modified
      let l:flag = " \u274b"
    else
      let l:flag = ""
    endif
  else
    let l:flag = "\U1f512"
  endif
  if empty(l:flag)
    let l:flags = "  "
  else
    let l:flags = l:flag
  endif
  return l:flags
endfunction

function s:stl_file_name_set_cwd_context(context)
  " Store cwd of current active window
  let a:context.original_cwd = getcwd()
  " Is it locally-set directory?
  if haslocaldir()
    let a:context.cwd_type = 'local'
  elseif haslocaldir(-1)
    let a:context.cwd_type = 'tabpage'
  else
    let a:context.cwd_type = 'global'
  endif
  " Set local working directory to window for which stl is drawn
  " This is for correct context of filename-modifiers
  silent execute "lcd ".getcwd(a:context.winnr)
endfunction
function! s:restore_cwd_context(context)
  " Restore original cwd of current active window
  if a:context.cwd_type ==# 'local'
    let l:cwd_type_char = 'l'
  elseif a:context.cwd_type ==# 'tabpage'
    let l:cwd_type_char = 't'
  elseif a:context.cwd_type ==# 'global'
    let l:cwd_type_char = ''
  endif
  silent execute l:cwd_type_char."cd ".a:context.original_cwd
endfunction
function! s:stl_file_name_set_result(context, result)
  let a:context.has_result = 1
  let a:context.filename = a:result
endfunction
function! s:stl_file_name_handle_all_cases(context, file_name_funcs)
  for fn in a:file_name_funcs
    call function(fn)(a:context)
    if a:context.has_result
      return a:context.filename
    endif
  endfor
endfunction
" Special cases for filename stl part
" Filetypes that should display only base file name
function! s:stl_file_name_simple_name_for_ft(context)
  let l:path_disabled_filetypes = ['help']
  let l:filetype = getbufvar(a:context.bufnr, '&filetype')
  if index(l:path_disabled_filetypes, l:filetype) >= 0
    call s:stl_file_name_set_result(a:context, fnamemodify(a:context.bufname, ':t'))
  endif
endfunction
" Empty name
function! s:stl_file_name_no_name(context)
  if empty(a:context.bufname)
    call s:stl_file_name_set_result(a:context, '[No Name]')
  endif
endfunction
" Shorten path relatively
function! s:stl_file_name_shorten_relative_path(context)
  let l:head_dir = fnamemodify(a:context.bufname, ':.:h')
  if l:head_dir == '.'
    call s:stl_file_name_set_result(a:context, fnamemodify(a:context.bufname, ':t'))
  else
    call s:stl_file_name_set_result(a:context, pathshorten(l:head_dir).'/'.fnamemodify(a:context.bufname, ':t'))
  endif
endfunction
" Which functions and in which order determine filename part
let s:stl_file_name_funcs = [
      \ 's:stl_file_name_simple_name_for_ft',
      \ 's:stl_file_name_no_name',
      \ 's:stl_file_name_shorten_relative_path',
      \]
function! s:stl_file_name(winnr)
  let l:bufnr = winbufnr(a:winnr)
  let l:context  = {
        \ 'original_cwd': '',
        \ 'cwd_type': '',
        \ 'bufnr': l:bufnr,
        \ 'bufname': bufname(l:bufnr),
        \ 'winnr': a:winnr,
        \ 'has_result': 0,
        \ 'filename': '',
        \}
  " Set correct working directory context
  call s:stl_file_name_set_cwd_context(l:context)
  let l:filename = s:stl_file_name_handle_all_cases(l:context, s:stl_file_name_funcs)
  call s:restore_cwd_context(l:context)
  return l:filename
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

function! s:stl()
  let l:stl = ""
  let l:stl .= s:highlight_stl_part(s:stl_cwd(), "STLCWD")
  let l:stl .= s:highlight_stl_part(s:stl_file_flags(0), "STLFlags")
  let l:stl .= s:stl_sep
  let l:stl .= "%<"
  let l:stl .= s:stl_file_name(0)
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part("%=", "STLEmpty")
  let l:stl .= s:stl_sep
  let l:stl .= s:stl_type()
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_location(), "STLLocation")
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_win_id(), "STLWinnr")
  return l:stl
endfunction

function! s:stlnc(winnr)
  let l:stl = ""
  let l:stl .= s:stl_cwd()
  let l:stl .= s:stl_file_flags(a:winnr)
  let l:stl .= s:stl_sep
  let l:stl .= "%<"
  let l:stl .= s:stl_file_name(a:winnr)
  let l:stl .= "%="
  let l:stl .= s:stl_win_id()
  return l:stl
endfunction

function s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

execute "setlocal statusline=%!<SNR>".s:SID()."_stl()"
augroup statusline_update
  autocmd!
  autocmd WinEnter,BufWinEnter * for n in range(1, winnr('$'))|
        \if n == winnr()|
        \call setwinvar(n, '&statusline', '%!<SNR>'.s:SID().'_stl()')|
        \else|
        \call setwinvar(n, '&statusline', '%!<SNR>'.s:SID().'_stlnc('.n.')')|
        \endif|
        \endfor
augroup end
