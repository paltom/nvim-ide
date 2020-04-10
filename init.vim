filetype plugin indent on
syntax on

" System clipboard {{{
" Clipboard tool must be installed (:help clipboard-tool)
" Conveniently yank text into clipboard
nnoremap gy "+y
nnoremap gY "+Y
" Conveniently paste text from clipboard
nnoremap gp "+p
nnoremap gP "+P
" Move cursor after pasted text (restore mappings)
nnoremap gap gp
nnoremap gaP gP
" Paste into lines below and above current line
nnoremap gop o<esc>"+p
nnoremap gOp O<esc>"+p
" Paste from clipboard in insert mode moving cursor after pasted text and stay
" in insert mode
inoremap <expr> <c-v> col(".") is# 1 ? "\<esc>\"+gPa" : "\<esc>\"+gpa"
" Preserve a way to insert special characters (restore mapping)
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
  let g:config_remove_trailing_whitespaces = v:true
  " Remove trailing whitespaces on buffer writing
  autocmd BufWrite *
        \ if g:config_remove_trailing_whitespaces|
        \   %s/\v\s+$//e|
        \ endif
augroup end

function! s:add_empty_lines(above, count) range
  let l:current_position = getcurpos()
  let l:new_position = [l:current_position[1], l:current_position[4]]
  let l:line_to_insert = l:new_position[0]
  if a:above
    let l:line_to_insert = l:new_position[0] - 1
    let l:new_position[0] = l:new_position[0] + a:count
  endif
  call append(l:line_to_insert, repeat([""], a:count))
  call cursor(l:new_position)
endfunction
" add empty line(s) above/below current line preserving cursor position in
" current line
nnoremap <silent> [<space> :<c-u>call <sid>add_empty_lines(v:true, v:count1)<cr>
nnoremap <silent> ]<space> :<c-u>call <sid>add_empty_lines(v:false, v:count1)<cr>
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
    try
      lnext
    catch /E553:/
      lfirst
    endtry
  elseif len(getqflist()) > 0
    try
      cnext
    catch /E553:/
      cfirst
    endtry
  else
    execute "normal! n"
  endif
endfunction
function! s:search_backward()
  if len(getloclist(0)) > 0
    try
      lprevious
    catch /E553:/
      llast
    endtry
  elseif len(getqflist()) > 0
    try
      cprevious
    catch /E553:/
      clast
    endtry
  else
    execute "normal! N"
  endif
endfunction
nnoremap <silent> ]s :<c-u>call <sid>search_forward()<cr>
nnoremap <silent> [s :<c-u>call <sid>search_backward()<cr>

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
set noequalalways
" Enable rich colors
set termguicolors
" Background should be dark (it is possible to switch it to light)
set background=light
" Clear vertical borders between splits
let &fillchars = "vert: "

" Load all colorscheme plugins listed above by plugin directory name
call config#ext_plugins#load("vim-one")

augroup config_colorscheme_update
  autocmd!
  " When switching colorschemes, make sure that custom highlight links are
  " restored
  autocmd ColorScheme * highlight! link Folded FoldColumn
  autocmd ColorScheme * highlight! link VertSplit StatusLineNC
augroup end
" Select colorscheme
" Allow italics to be displayed (e.g. comments)
let g:one_allow_italics = 1
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
  function! s:disable_cursorline_in_diff(diff_enabled)
  if a:diff_enabled
      setlocal nocursorline
  else
      setlocal cursorline
  endif
  endfunction
  autocmd!
  " Draw cursorline in active window but not when diffs are displayed in the
  " window
  autocmd VimEnter * setlocal cursorline
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter *
        \ call s:disable_cursorline_in_diff(&diff)
  " Disable cursorline when diff option is set manually
  autocmd OptionSet diff
        \ call s:disable_cursorline_in_diff(v:option_new)
  " Do not show cursorline in inactive windows
  autocmd WinLeave * setlocal nocursorline
augroup end

" Show number column with numbers relative to current line (current line in
" absolute numbers)
set number relativenumber numberwidth=5

" Statusline settings
setlocal statusline=%!config#statusline#active()
augroup config_statusline_update
  autocmd!
  autocmd WinEnter,BufWinEnter * setlocal statusline=%!config#statusline#active()
  autocmd WinLeave * setlocal statusline=%!config#statusline#inactive()
augroup end

function! s:ft_help_filename(bufname)
  if getbufvar(a:bufname, "&filetype") ==# "help"
    return g:config#statusline#parts#filename#simple(a:bufname)
  endif
  return v:null
endfunction
call config#statusline#custom_filename_handler(funcref("s:ft_help_filename"))

" Tabline settings
" Display tabline when there are at least two tabpages
set showtabline=1
" Do not use GUI external tabline
set guioptions-=e
set tabline=%!config#tabline#tabline()
" }}}

" vim:foldmethod=marker
