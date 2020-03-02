filetype plugin indent on

" System clipboard {{{
" Clipboard tool must be installed (:help clipboard-tool)
" Conveniently yank text into clipboard
nnoremap gy "+y
nnoremap gY "+Y
" Conveniently paste text from clipboard
nnoremap gp "+p
nnoremap gP "+P
" Move cursor after pasted text
nnoremap gap gp
nnoremap gaP gP
" Paste into lines below and above current line
nnoremap gop o<esc>"+p
nnoremap gOp O<esc>"+p
" Paste from clipboard in insert mode moving cursor after pasted text and stay
" in insert mode
inoremap <expr> <c-v> col('.') == 1 ? "\<esc>\"+gPa" : "\<esc>\"+gpa"
" Preserve a way to insert special characters
inoremap <c-g><c-v> <c-v>
" Yank/paste into/from clipboard in visual mode
vnoremap gy "+y
vnoremap gp "+p
" }}}

" Basic auto-formatting settings {{{
" Tab characters are replaced by 4 spaces when entered
set expandtab softtabstop=4 tabstop=4
" Lines are automatically indented by multiple of 4 characters
set autoindent smartindent shiftwidth=4 shiftround

augroup config_replace_tabs
  autocmd!
  " Replace tab characters with spaces on buffer writing
  autocmd BufWrite * retab
augroup end

augroup config_remove_trailing_whitespaces
  autocmd!
  " There is possibility to turn off removing trailing whitespaces on buffer
  " writing
  let g:remove_trailing_whitespaces = v:true
  " Remove trailing whitespaces on buffer writing
  autocmd BufWrite *
        \ if g:remove_trailing_whitespaces|
        \   %s/\v\s+$//e|
        \ endif
augroup end

function! s:add_empty_lines(direction, count) range
  " direction = 0 means above current line
  " direction = 1 means below current line
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
" add empty line(s) above/below current line preserving cursor position in
" current line
nnoremap <silent> [<space> :<c-u>call <sid>add_empty_lines(0, v:count1)<cr>
nnoremap <silent> ]<space> :<c-u>call <sid>add_empty_lines(1, v:count1)<cr>
" }}}

" Easy various movements {{{
" Move between windows no matter which mode is active
nnoremap <a-h> <c-w>h
nnoremap <a-j> <c-w>j
nnoremap <a-k> <c-w>k
nnoremap <a-l> <c-w>l
inoremap <a-h> <c-\><c-n><c-w>h
inoremap <a-j> <c-\><c-n><c-w>j
inoremap <a-k> <c-\><c-n><c-w>k
inoremap <a-l> <c-\><c-n><c-w>l
vnoremap <a-h> <c-w>h
vnoremap <a-j> <c-w>j
vnoremap <a-k> <c-w>k
vnoremap <a-l> <c-w>l
tnoremap <a-h> <c-\><c-n><c-w>h
tnoremap <a-j> <c-\><c-n><c-w>j
tnoremap <a-k> <c-\><c-n><c-w>k
tnoremap <a-l> <c-\><c-n><c-w>l
" Turn off terminal mode more easily
tnoremap <c-w> <c-\><c-n>

" Move to beginning/end of line
noremap H ^
noremap L $

" Move between tabpages
nnoremap <silent> [t :tabprevious<cr>
nnoremap <silent> ]t :tabnext<cr>
" Cycle through tabpages
nnoremap <silent> <c-t>t :tabnext<cr>
nnoremap <silent> <c-t><c-t> :tabnext<cr>

" Move between searches
" If location list for window is present, use its results, otherwise use
" quickfix list
" If neither location nor quickfix are present, use current search
" register
function! s:search_forward()
  if len(getloclist(0)) > 0
    lnext
  elseif len(getqflist()) > 0
    cnext
  else
    execute "normal! n"
  endif
endfunction
function! s:search_backward()
  if len(getloclist(0)) > 0
    lprevious
  elseif len(getqflist()) > 0
    cprevious
  else
    execute "normal! N"
  endif
endfunction
nnoremap <silent> ]s :call <sid>search_forward()<cr>
nnoremap <silent> [s :call <sid>search_backward()<cr>

" More convenient selecting of popupmenu items
inoremap <c-j> <c-n>
inoremap <c-k> <c-p>

" More convenient movements through vertical wildmenu
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

" Easier switching to alternate (previous) buffer
nnoremap <backspace> <c-^>
" }}}

" Search settings {{{
" Search ignoring case when only lowercase characters are used
set ignorecase smartcase
" Highlight partial search results when entering search query
" Highlight only during entering search query
set nohlsearch incsearch

augroup config_highlight_searches
  autocmd!
  " Turn on highlighting only during searching
  autocmd CmdLineEnter /,\? set hlsearch
  " Disable search highlights after search query is entered
  autocmd CmdLineLeave /,\? set nohlsearch
augroup end

" Search for visually selected text
vnoremap / y/<c-r>"<cr>
" Preserve a way to go to search in visual mode
vnoremap g/ /
" }}}

" Various theme & visuals settings {{{
" Allow italics to be displayed (e.g. comments)
let g:one_allow_italics = 1
" Enable rich colors
set termguicolors
" Background should be dark (it is possible to switch it to light)
set background=dark
" Clear vertical borders between splits
let &fillchars = "vert: "

" Map colorscheme plugin directory to colorscheme name as visible by Vim
let s:colorscheme_plugins = {"vim-one": "one"}
" Load all colorscheme plugins listed above by plugin directory name
call ext#plugins#load(keys(s:colorscheme_plugins))

augroup config_colorscheme_update
  autocmd!
  " When switching colorschemes, make sure that custom highlight links are
  " restored
  " XXX: Shouldn't be for ALL colorschemes?
  execute "autocmd ColorScheme ".join(values(s:colorscheme_plugins), ",").
              \" highlight! link Folded FoldColumn"
  execute "autocmd ColorScheme ".join(values(s:colorscheme_plugins), ",").
              \" highlight! link VertSplit StatusLineNC"
augroup end
" Select colorscheme
colorscheme one

" Don't wrap long lines
set nowrap
" Always show some context above/below/before/after cursor even when reaching
" screen edge
set scrolloff=3
set sidescroll=1 sidescrolloff=10
" Make tabs and trailing spaces visible
let &listchars = "tab:\u00bb ,trail:\u2423"
set list
" Make long lines visually distinguishable
let &listchars .= ",precedes:\u27ea,extends:\u27eb"

augroup config_colorcolumn_in_active_window
  autocmd!
  " Draw color column in active window at 80 characters (warning) and after
  " 120 characters (limit for line length)
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter *
        \ let &l:colorcolumn = "80,".join(range(120, 999), ",")
  " In inactive windows, make whole window visually distinguishable
  autocmd WinLeave *
        \ let &l:colorcolumn = join(range(1, 999), ",")
augroup end
augroup config_cursorline_in_active_window
  autocmd!
  " Draw cursorline in active window but not when diffs are displayed in the
  " window
  autocmd VimEnter * setlocal cursorline
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter *
        \ if !&diff|
        \   setlocal cursorline|
        \ else|
        \   setlocal nocursorline|
        \ endif
  " Do not show cursorline in inactive windows
  autocmd WinLeave * setlocal nocursorline
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
  " Disable cursorline in active window when diff option is set manually
  autocmd OptionSet diff
        \ call <sid>disable_cursorline_in_diff(v:option_new)
augroup end

" Show number column with numbers relative to current line (current line in
" absolute numbers)
set number relativenumber numberwidth=5

" Statusline {{{
" Statusline colors {{{
function! s:update_statusline_colors()
  " Function updating highlight groups used for statusline parts
  function! s:get_highlight_color(highlight_name, attribute)
    " Helper function to get color of given attribute of given highlight group
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
  " STLFlags is used for file status flags
  execute "highlight STLFlags guibg=".l:stl_guibg." guifg=".l:stl_flags_guifg
  " STLLocation is used for location in file marker
  execute "highlight STLLocation guifg=".l:stl_guibg." guibg=".l:stl_loc_guibg
  " STLCWD is used for current working directory part
  execute "highlight STLCWD guifg=".l:stl_cwd_guifg." gui=inverse,bold"
  " STLEmpty is used for separator in active window's statusline
  highlight STLEmpty gui=inverse
  " STLWinnr is used for window number part
  highlight STLWinnr gui=bold
endfunction
" Create statusline colors when starting Vim
call s:update_statusline_colors()
augroup config_statusline_colors
  autocmd!
  " Make sure that statusline highlights are available after changing
  " colorscheme
  " XXX: Shouldn't be for ALL colorschemes?
  execute "autocmd ColorScheme ".join(values(s:colorscheme_plugins), ",")
        \" call s:update_statusline_colors()"
augroup end
" }}}

" Utility functions {{{
function s:sid()
  " Get SID of current script (useful even in init.vim!)
  return matchstr(expand('<sfile>'), '<snr>\zs\d\+\ze_SID$')
endfunction

function! s:highlight_stl_part(part, highlight_group)
  " Helper function for highlighting statusline part
  return "%#".a:highlight_group."#".a:part."%#StatusLine#"
endfunction
" }}}

" Statusline parts {{{
" Statusline parts separator
let s:stl_sep = " "

" Statusline current working directory part
" Current working directory path is relative to home directory when possible
" Current working directory path is shortened up to last directory (exclusive)
function! s:stl_cwd()
  return "%{pathshorten(fnamemodify(getcwd(), ':~'))}:"
endfunction

" Statusline file status flags part
" When file is not modifiable or readonly, display lockpad character
" When file is modified, display centered asterisk character
function! s:stl_file_flags(winid)
  let l:bufnr = winbufnr(a:winid)
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
  " Store cwd context of current active window
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
  silent execute "lcd ".getcwd(a:context.winid)
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
function! s:filename_set_result(context, result)
  " Helper function for marking that filename function returned result (early
  " exit)
  let a:context.has_result = 1
  let a:context.filename = a:result
endfunction
function! s:filename_handle_all_cases(context, file_name_funcs)
  " Helper function for trying all cases of filename handling functions
  " As soon as on of functions returns result, return it and don't try
  " remaining functions
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
" Function handling filename displaying for given filetype will receive
" bufname as argument
let g:statusline_filename_special_filetypes = []
let g:statusline_filename_special_filetypes =
      \ add(g:statusline_filename_special_filetypes, {
      \   "filetype": "help",
      \   "filename_function": { bufname -> fnamemodify(bufname, ':t') }
      \})
function! s:stl_filename_filetype(context)
  " Function for handling custom filetype handling
  let l:filetype = getbufvar(a:context.bufnr, '&filetype')
  let l:special_filetypes_map = copy(g:statusline_filename_special_filetypes)
  let l:special_filetype = filter(l:special_filetypes_map,
        \ 'v:val.filetype == l:filetype')
  unlet l:special_filetypes_map
  if len(l:special_filetype) > 0
    " Last entry for given filetype is used
    let l:special_filetype = l:special_filetype[-1]
    call s:filename_set_result(a:context,
          \ l:special_filetype.filename_function(a:context.bufname))
  endif
endfunction
" Empty filename handling (buffer not written to disk)
function! s:filename_no_name(context)
  if empty(a:context.bufname)
    call s:filename_set_result(a:context, '[No Name]')
  endif
endfunction
" Regular filename handling
" Shorten path relatively to current working directory
" Leave full name of directory containing file
function! s:filename_shorten_relative_path(context)
  let l:head_dir = fnamemodify(a:context.bufname, ':.:h')
  if l:head_dir == '.'
    " If file is in current working directory, do not display cwd
    call s:filename_set_result(a:context, fnamemodify(a:context.bufname, ':t'))
  else
    call s:filename_set_result(a:context, pathshorten(l:head_dir).'/'.fnamemodify(a:context.bufname, ':t'))
  endif
endfunction
" Simple filename
function! s:filename_simple(context)
  let l:filename = fnamemodify(a:context.bufname, ":t")
  call s:filename_set_result(a:context, l:filename)
endfunction
" Which functions and in which order (precedence) determine filename part
let s:stl_filename_funcs = [
      \ 's:stl_filename_filetype',
      \ 's:filename_no_name',
      \ 's:filename_shorten_relative_path',
      \]
function! s:stl_filename(winid)
  let l:bufnr = winbufnr(a:winid)
  " Store context of window for which statusline is drawn
  let l:context  = {
        \ 'original_cwd': '',
        \ 'cwd_type': '',
        \ 'bufnr': l:bufnr,
        \ 'bufname': bufname(l:bufnr),
        \ 'winid': a:winid,
        \ 'has_result': 0,
        \ 'filename': '',
        \}
  " Set correct working directory context (for window for which statusline is
  " drawn, not active window)
  call s:stl_filename_set_cwd_context(l:context)
  let l:filename = s:filename_handle_all_cases(l:context, s:stl_filename_funcs)
  " Restore window's original current working directory
  call s:stl_filename_restore_cwd_context(l:context)
  return l:filename
endfunction
" }}}

" Filetype statusline part
function! s:stl_type()
  return "%(%y%q%w%)"
endfunction

" Location if file statusline part
function! s:stl_location()
  let l:location_indicators_list = [
        \ ["\u2588"],
        \ ["\u2588", " "],
        \ ["\u2588", "\u2584", " "],
        \ ["\u2588", "\u2585", "\u2583", " "],
        \ ["\u2588", "\u2586", "\u2584", "\u2582", " "],
        \ ["\u2588", "\u2586", "\u2585", "\u2583", "\u2582", " "],
        \ ["\u2588", "\u2587", "\u2585", "\u2584", "\u2583", "\u2582", " "],
        \ ["\u2588", "\u2587", "\u2586", "\u2585", "\u2583", "\u2582", "\u2581", " "],
        \ ["\u2588", "\u2587", "\u2586", "\u2585", "\u2584", "\u2583", "\u2582", "\u2581", " "],
        \]
  let l:curline = line(".")
  let l:file_lines = line("$")
  " Make count a float number to enable floating-point arithmetics
  let l:indicators_count = eval(len(l:location_indicators_list).".0")
  if l:file_lines < l:indicators_count
    return l:location_indicators_list[l:file_lines - 1][l:curline - 1]
  else
    let l:indicator_index = float2nr(floor(l:indicators_count*(l:curline - 1)/l:file_lines))
    return l:location_indicators_list[-1][l:indicator_index]
  endif
endfunction

" Display window id statusline part
function! s:stl_win_nr()
  return "[%{winnr()}]"
endfunction
" }}}

" Active window statusline drawing
function! s:stl(winid)
  let l:stl = ""
  let l:stl .= s:highlight_stl_part(s:stl_cwd(), "STLCWD")
  let l:stl .= s:highlight_stl_part(s:stl_file_flags(a:winid), "STLFlags")
  let l:stl .= s:stl_sep
  let l:stl .= "%<"
  let l:stl .= s:stl_filename(a:winid)
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part("%=", "STLEmpty")
  let l:stl .= s:stl_sep
  let l:stl .= s:stl_type()
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_location(), "STLLocation")
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_win_nr(), "STLWinnr")
  return l:stl
endfunction

" Inactive windows statusline drawing
function! s:stlnc(winid)
  let l:stl = ""
  let l:stl .= s:stl_cwd()
  let l:stl .= s:stl_file_flags(a:winid)
  let l:stl .= s:stl_sep
  let l:stl .= "%<"
  let l:stl .= s:stl_filename(a:winid)
  let l:stl .= "%="
  let l:stl .= s:stl_win_nr()
  return l:stl
endfunction


execute "setlocal statusline=%!<snr>".s:sid()."_stl(".win_getid().")"
augroup config_statusline_update
  autocmd!
  " Set correct statusline functions for all windows in tabpage when changing
  " windows
  autocmd WinEnter,BufWinEnter *
        \ for n in range(1, winnr('$'))|
        \   if n == winnr()|
        \     call setwinvar(n, '&statusline', '%!<snr>'.s:sid().'_stl('.win_getid(n).')')|
        \   else|
        \     call setwinvar(n, '&statusline', '%!<snr>'.s:sid().'_stlnc('.win_getid(n).')')|
        \   endif|
        \ endfor
augroup end
" }}}

" Tabline {{{
" Display tabline when there are at least two tabpages
set showtabline=1
" Do not use GUI external tabline
set guioptions-=e

" Tabline parts separator
let s:tbl_sep = " "

" Filename tabline part
let s:tbl_filename_funcs = [
      \ 's:filename_no_name',
      \ 's:filename_simple',
      \]
function! s:tbl_filename(tabpagenr)
  let l:tabpage_curwin = tabpagewinnr(a:tabpagenr)
  let l:curwin_bufnr = tabpagebuflist(a:tabpagenr)[l:tabpage_curwin - 1]
  let l:bufname = bufname(l:curwin_bufnr)
  let l:context = {
        \ 'bufname': l:bufname,
        \ 'has_result': 0,
        \ 'filename': '',
        \}
  return s:filename_handle_all_cases(l:context, s:tbl_filename_funcs)
endfunction

" If any window in tabpage is modified
function! s:tbl_modified(tabpagenr)
  for winnr in range(1, tabpagewinnr(a:tabpagenr, "$"))
    if gettabwinvar(a:tabpagenr, winnr, '&modified')
      return "*"
    endif
  endfor
  return " "

endfunction

" All tabpages tabline drawing (:help setting-tabline)
function! s:tbl()
  let l:tbl = ""
  for tpi in range(1, tabpagenr("$"))
    if tpi == tabpagenr()
      " Active tabpage
      let l:tbl .= "%#TablineSel#"
    else
      " Inactive tabpage
      let l:tbl .= "%#Tabline#"
    endif
    let l:tbl .= "%".tpi."T"
    let l:tbl .= s:tbl_sep
    let l:tbl .= s:tbl_modified(tpi)
    let l:tbl .= s:tbl_sep
    let l:tbl .= s:tbl_filename(tpi)
    let l:tbl .= s:tbl_sep
    let l:tbl .= '['.tpi.']'
  endfor
  let l:tbl .= "%#TablineFill#"
  let l:tbl .= "%="
  return l:tbl
endfunction
execute "set tabline=%!<snr>".s:sid()."_tbl()"
" }}}
" }}}

" Extensions plugins settings {{{
" }}}

" vim:foldmethod=marker
