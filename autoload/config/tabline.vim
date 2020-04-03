let config#tabline# = {}

let config#tabline#.sep = " "

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
        \ g:config#tabline#.sep,
        \ g:config#tabline#parts#.modified(a:tabpagenr),
        \ g:config#tabline#.sep,
        \ g:config#tabline#parts#.filename(a:tabpagenr),
        \ g:config#tabline#.sep,
        \ "[".a:tabpagenr."]",
        \])
  return l:label
endfunction

function! config#tabline#.tabline()
  let l:tbl = []
  for tabpagenr in range(1, tabpagenr("$"))
    let l:tbl = extend(l:tbl, s:tabpage_label(tabpagenr))
  endfor
  let l:tbl = add(l:tbl, "%#TablineFill#")
  let l:tbl = add(l:tbl, "%=")
  return join(l:tbl, "")
endfunction
