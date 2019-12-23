set expandtab softtabstop=4 tabstop=4 shiftwidth=4 shiftround
set autoindent smartindent
augroup format_white_characters
  autocmd!
  autocmd BufWrite * retab
  let g:remove_trailing_whitespaces = 1
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
