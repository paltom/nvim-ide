set expandtab softtabstop=4 tabstop=4 shiftwidth=4 shiftround
set autoindent smartindent
augroup format_white_characters
  autocmd!
  autocmd BufWrite * retab
  let g:remove_trailing_whitespaces = 1
  autocmd BufWrite * if g:remove_trailing_whitespaces|%s/\v\s+$//e|endif
augroup end
