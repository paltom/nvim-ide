let list# = {}

function! list#.contains(list, elem)
  return index(a:list, a:elem) >= 0
endfunction

function! list#.unique_insert(list, elem, ...)
  let l:index = get(a:000, 0, 0)
  let l:list = copy(a:list)
  if !g:list#.contains(l:list, a:elem)
    let l:list = insert(l:list, a:elem, l:index)
  endif
  return l:list
endfunction
