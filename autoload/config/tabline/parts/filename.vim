let config#tabline#parts#filename# = {}

let s:filename_special_cases = [
      \]
function! config#tabline#parts#filename#.add_handler(funcref)
  let s:filename_special_cases = g:list#.unique_append(s:filename_special_cases, a:funcref)
endfunction

function! s:filename_special_cases(bufname)
  return g:func#.until_result(s:filename_special_cases)(a:bufname)
endfunction

let config#tabline#parts#filename#.funcs = [
      \ config#statusline#parts#filename#.empty,
      \ funcref("s:filename_special_cases"),
      \ config#statusline#parts#filename#.simple,
      \]
