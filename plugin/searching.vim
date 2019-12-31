set ignorecase smartcase
set nohlsearch incsearch
augroup highlight_searches
  autocmd!
  autocmd CmdLineEnter /,\? set hlsearch
  autocmd CmdLineLeave /,\? set nohlsearch
augroup end

vnoremap / y/<c-r>"<cr>
vnoremap g/ /
