filetype plugin indent on

" Easy access to system clipboard {{{
nnoremap gy "+y
nnoremap gY "+Y
nnoremap gp "+p
nnoremap gap gp
nnoremap gaP gP
nnoremap gP "+P
nnoremap gop o<esc>"+p
nnoremap gOp O<esc>"+p
inoremap <expr> <c-v> col('.') == 1 ? "\<esc>\"+gPa" : "\<esc>\"+gpa"
inoremap <c-g><c-v> <c-v>
vnoremap gy "+y
vnoremap gp "+p
" }}}

" Basic auto-formatting settings {{{
set expandtab softtabstop=4 tabstop=4
set autoindent smartindent shiftwidth=4 shiftround

augroup config_replace_tabs
  autocmd!
  autocmd BufWrite * retab
augroup end

augroup config_remove_trailing_whitespaces
  autocmd!
  let g:remove_trailing_whitespaces = v:true
  autocmd BufWrite *
        \ if g:remove_trailing_whitespaces|
        \   %s/\v\s+$//e|
        \ endif
augroup end

function! s:add_empty_lines(direction, count) range
  " Direction = 0 means above current line
  " Direction = 1 means below current line
  let l:current_position = getcurpos()
  let l:new_position = [l:current_position[1], l:current_position[4]]
  if a:direction
    let l:where_to_insert = l:new_position[0]
  else
    let l:where_to_insert = l:new_position[0] - 1
    let l:new_position[0] = l:new_position[0] + a:count
  endif
  call append(l:where_to_insert, repeat([""], a:count))
  call cursor(l:new_position)
endfunction
nnoremap <silent> [<space> :<c-u>call <SID>add_empty_lines(0, v:count1)<cr>
nnoremap <silent> ]<space> :<c-u>call <SID>add_empty_lines(1, v:count1)<cr>
" }}}

" Easy various movements {{{
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

nnoremap <backspace> <c-^>
" }}}

" Search settings {{{
set ignorecase smartcase
set nohlsearch incsearch

augroup config_highlight_searches
  autocmd!
  autocmd CmdLineEnter /,\? set hlsearch
  autocmd CmdLineLeave /,\? set nohlsearch
augroup end

vnoremap / y/<c-r>"<cr>
vnoremap g/ /
" }}}

" Various theme & visuals settings {{{
let g:one_allow_italics = 1
set termguicolors
set background=dark
let &fillchars = "vert: "

" Map colorscheme plugin directory to colorscheme name as visible by Vim
let s:colorscheme_plugins = {"vim-one": "one"}
call ext#plugins#load(keys(s:colorscheme_plugins))

augroup config_colorscheme_update
  autocmd!
  execute "autocmd ColorScheme ".join(values(s:colorscheme_plugins), ",").
              \" highlight! link Folded FoldColumn"
  execute "autocmd ColorScheme ".join(values(s:colorscheme_plugins), ",").
              \" highlight! link VertSplit StatusLineNC"
augroup end
colorscheme one

set nowrap
set scrolloff=3
set sidescroll=1 sidescrolloff=10
let &listchars = "tab:\u00bb ,trail:\u2423"
set list
let &listchars .= ",precedes:\u27ea,extends:\u27eb"

augroup config_colorcolumn_in_active_window
  autocmd!
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter *
        \ let &l:colorcolumn = "80,".join(range(120, 999), ",")
  autocmd WinLeave *
        \ let &l:colorcolumn = join(range(1, 999), ",")
augroup end
augroup config_cursorline_in_active_window
  autocmd!
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter *
        \ if !&diff|
        \   setlocal cursorline|
        \ else|
        \   setlocal nocursorline|
        \ endif
  autocmd WinLeave * setlocal nocursorline
  autocmd VimEnter * setlocal cursorline
augroup end
function! s:disable_cursorline_in_diff(new_option_value)
  if a:new_option_value
    setlocal nocursorline
  else
    setlocal cursorline
  endif
endfunction
augroup config_cursorline_in_diff_windows
  autocmd!
  autocmd OptionSet diff
        \ call <SID>disable_cursorline_in_diff(v:option_new)
augroup end

set number relativenumber numberwidth=5

" Statusline {{{
" Statusline colors - using vim-one colors {{{
function! s:update_statusline_colors()
  function! s:get_highlight_color(highlight_name, attribute)
    return filter(
        \   map(
        \     filter(
        \       split(execute("highlight ".a:highlight_name)),
        \     'v:val =~ "="'),
        \   'split(v:val, "=")'),
        \ 'v:val[0] ==? "'.a:attribute.'"')[0][1]
  endfunction
  let l:stl_guibg = s:get_highlight_color("StatusLine", "guibg")
  let l:stl_flags_guifg = s:get_highlight_color("Search", "guibg")
  let l:stl_loc_guibg = s:get_highlight_color("Directory", "guifg")
  let l:stl_cwd_guifg = s:get_highlight_color("String", "guifg")
  execute "highlight STLFlags guibg=".l:stl_guibg." guifg=".l:stl_flags_guifg
  execute "highlight STLLocation guifg=".l:stl_guibg." guibg=".l:stl_loc_guibg
  execute "highlight STLCWD guifg=".l:stl_cwd_guifg." gui=inverse,bold"
  highlight STLEmpty gui=inverse
  highlight STLWinnr gui=bold
endfunction
call s:update_statusline_colors()
augroup config_statusline_colors
  autocmd!
  execute "autocmd ColorScheme ".join(values(s:colorscheme_plugins), ",")
        \" call s:update_statusline_colors()"
augroup end
" }}}

" Utility functions {{{
function s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function! s:highlight_stl_part(part, highlight_group)
  return "%#".a:highlight_group."#".a:part."%#StatusLine#"
endfunction
" }}}

" Statusline parts {{{
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

" Filename part functions {{{
function s:stl_filename_set_cwd_context(context)
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
function! s:stl_filename_restore_cwd_context(context)
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
function! s:stl_filename_set_result(context, result)
  let a:context.has_result = 1
  let a:context.filename = a:result
endfunction
function! s:stl_filename_handle_all_cases(context, file_name_funcs)
  for fn in a:file_name_funcs
    call function(fn)(a:context)
    if a:context.has_result
      return a:context.filename
    endif
  endfor
endfunction
" Special cases for filename stl part
" Filetypes that should display custom file name
" Those can be registered by plugin later
let g:statusline_filename_special_filetypes = []
let g:statusline_filename_special_filetypes =
      \ add(g:statusline_filename_special_filetypes, {
      \   "filetype": "help",
      \   "filename_function": { bufname -> fnamemodify(bufname, ':t') }
      \})
function! s:stl_filename_filetype(context)
  let l:filetype = getbufvar(a:context.bufnr, '&filetype')
  let l:special_filetypes_map = copy(g:statusline_filename_special_filetypes)
  let l:special_filetype = filter(l:special_filetypes_map,
        \ 'v:val.filetype == l:filetype')
  unlet l:special_filetypes_map
  if len(l:special_filetype) > 0
    let l:special_filetype = l:special_filetype[-1]
    call s:stl_filename_set_result(a:context,
          \ l:special_filetype.filename_function(a:context.bufname))
  endif
endfunction
" Empty name
function! s:stl_filename_no_name(context)
  if empty(a:context.bufname)
    call s:stl_filename_set_result(a:context, '[No Name]')
  endif
endfunction
" Shorten path relatively
function! s:stl_filename_shorten_relative_path(context)
  let l:head_dir = fnamemodify(a:context.bufname, ':.:h')
  if l:head_dir == '.'
    call s:stl_filename_set_result(a:context, fnamemodify(a:context.bufname, ':t'))
  else
    call s:stl_filename_set_result(a:context, pathshorten(l:head_dir).'/'.fnamemodify(a:context.bufname, ':t'))
  endif
endfunction
" Which functions and in which order determine filename part
let s:stl_filename_funcs = [
      \ 's:stl_filename_filetype',
      \ 's:stl_filename_no_name',
      \ 's:stl_filename_shorten_relative_path',
      \]
function! s:stl_filename(winnr)
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
  call s:stl_filename_set_cwd_context(l:context)
  let l:filename = s:stl_filename_handle_all_cases(l:context, s:stl_filename_funcs)
  call s:stl_filename_restore_cwd_context(l:context)
  return l:filename
endfunction
" }}}

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
" }}}

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

execute "setlocal statusline=%!<SNR>".s:SID()."_stl()"
augroup statusline_update
  autocmd!
  autocmd WinEnter,BufWinEnter *
        \ for n in range(1, winnr('$'))|
        \   if n == winnr()|
        \     call setwinvar(n, '&statusline', '%!<SNR>'.s:SID().'_stl()')|
        \   else|
        \     call setwinvar(n, '&statusline', '%!<SNR>'.s:SID().'_stlnc('.n.')')|
        \   endif|
        \ endfor
augroup end
" }}}

" Tabline {{{
" }}}
" }}}

" Extensions plugins settings {{{
" }}}

" vim:foldmethod=marker
