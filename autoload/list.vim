function! list#contains(list, elem)
  return index(a:list, a:elem) >= 0
endfunction

function! list#unique_insert(list, elem, ...) abort
  if a:0 > 1
    throw "Too many arguments for function 'list#.unique_insert'"
  endif
  let l:index = get(a:000, 0, 0)
  const l:list = copy(a:list)
  if !list#contains(l:list, a:elem)
    call insert(l:list, a:elem, l:index)
  endif
  return l:list
endfunction

function! list#unique_append(list, elem)
  return list#unique_insert(a:list, a:elem, len(a:list))
endfunction

function! s:list_wrapper(list_func, funcref)
  function! s:_list_wrapper(list) closure
    let l:list = copy(a:list)
    return call(a:list_func, [l:list, a:funcref])
  endfunction
  return func#wrap#list_vararg(funcref("s:_list_wrapper"))
endfunction
function! list#map(funcref)
  return s:list_wrapper("map", a:funcref)
endfunction
function! list#filter(funcref)
  return s:list_wrapper("filter", a:funcref)
endfunction
