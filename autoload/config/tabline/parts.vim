let config#tabline#parts# = {}

function! config#tabline#parts#.modified(tabpagenr)
  " check if any window in tabpage is modified
  for winnr in range(1, tabpagewinnr(a:tabpagenr, "$"))
    if gettabwinvar(a:tabpagenr, winnr, "&modified")
      return "*"
    endif
  endfor
  return ""
endfunction

function! config#tabline#parts#.filename(tabpagenr)
  let l:current_winnr = tabpagewinnr(a:tabpagenr)
  let l:bufnr = tabpagebuflist(a:tabpagenr)[l:current_winnr - 1]
  let l:bufname = bufname(l:bufnr)
  return g:func#.until_result(g:config#tabline#parts#filename#.funcs)(l:bufname)
endfunction
