let list# = {}

function! list#.contains(list, elem)
  return index(a:list, a:elem) >= 0
endfunction

function! list#.unique_insert(list, elem, ...) abort
  if a:0 > 1
    throw "Too many arguments for function 'list#.unique_insert'"
  endif
  let l:index = get(a:000, 0, 0)
  const l:list = copy(a:list)
  if !g:list#.contains(l:list, a:elem)
    call insert(l:list, a:elem, l:index)
  endif
  return l:list
endfunction

function! list#.unique_append(list, elem)
  return g:list#.unique_insert(a:list, a:elem, len(a:list))
endfunction

function! s:list_wrapper(list_func, funcref)
  function! s:_list_wrapper(list) closure
    let l:list = copy(a:list)
    return call(a:list_func, [l:list, a:funcref])
  endfunction
  return funcref("s:_list_wrapper")
endfunction
let list#.map = funcref("s:list_wrapper", ["map"])
let list#.filter = funcref("s:list_wrapper", ["filter"])