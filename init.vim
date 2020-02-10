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

augroup format_white_characters
  autocmd!
  autocmd BufWrite * retab
  let g:remove_trailing_whitespaces = v:true
  autocmd BufWrite * if g:remove_trailing_whitespaces|%s/\v\s+$//e|endif
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

augroup highlight_searches
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

let s:colorscheme_plugin = "vim-one"
call ext#plugins#load([s:colorscheme_plugin])

augroup colorscheme_fixes_init
  autocmd!
  autocmd ColorScheme one highlight! link Folded FoldColumn
  autocmd ColorScheme one highlight! link VertSplit StatusLineNC
augroup end
colorscheme one

set scrolloff=3

set number relativenumber numberwidth=5

let &listchars = "tab:\u00bb ,trail:\u2423"
set list
set nowrap sidescroll=1 sidescrolloff=10
let &listchars .= ",precedes:\u27ea,extends:\u27eb"

let &fillchars = "vert: "

augroup colorcolumn_in_active_window
  autocmd!
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter * let &l:colorcolumn = "80,".join(range(120, 999), ",")
  autocmd WinLeave * let &l:colorcolumn = join(range(1, 999), ",")
augroup end

augroup cursorline_in_active_window
  autocmd!
  autocmd BufNewFile,BufRead,BufWinEnter,WinEnter * if !&diff|setlocal cursorline|else|setlocal nocursorline|endif
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
augroup cursorline_in_diff_windows
  autocmd!
  autocmd OptionSet diff call <SID>disable_cursorline_in_diff(v:option_new)
augroup end
" }}}

" Basic plugins settings {{{
" need to postpone calling function until statusline plugin is loaded
autocmd SourcePost *statusline.vim ++once
            \ call statusline#register_filename_for_ft('help',
            \       { bufname -> fnamemodify(bufname, ':t') })
" }}}

" vim:foldmethod=marker
