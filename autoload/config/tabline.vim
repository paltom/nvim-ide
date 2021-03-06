let config#tabline#sep = " "

function! s:tabpage_label(tabpagenr)
  if a:tabpagenr == tabpagenr()
    " active tabpage
    let l:label = ["%#TablineSel#"]
  else
    " inactive tabpage
    let l:label = ["%#Tabline#"]
  endif
  let l:label = extend(l:label, [
        \ "%".a:tabpagenr."T",
        \ g:config#tabline#sep,
        \ config#tabline#parts#modified(a:tabpagenr),
        \ g:config#tabline#sep,
        \ config#tabline#parts#filename(a:tabpagenr),
        \ g:config#tabline#sep,
        \ "[".a:tabpagenr."]",
        \])
  return l:label
endfunction

function! config#tabline#tabline()
  let l:tbl = []
  for tabpagenr in range(1, tabpagenr("$"))
    let l:tbl = extend(l:tbl, s:tabpage_label(tabpagenr))
  endfor
  let l:tbl = add(l:tbl, "%#TablineFill#")
  let l:tbl = add(l:tbl, "%=")
  return join(l:tbl, "")
endfunction

function! config#tabline#custom_filename_handler(handler)
  return config#tabline#parts#filename#add_handler(a:handler)
endfunction
