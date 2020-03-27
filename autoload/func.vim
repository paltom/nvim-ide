function! func#map(func)
  function! s:map(func, list)
    let l:list = copy(a:list)
    let l:list = map(l:list, a:func)
    return l:list
  endfunction
  return function("s:map", [a:func])
endfunction

function! func#filter(func)
  function! s:filter(func, list)
    let l:list = copy(a:list)
    let l:list = filter(l:list, a:func)
    return l:list
  endfunction
  return function("s:filter", [a:func])
endfunction

function! func#compose(funcs)
  function! s:compose(funcs, arg)
    let l:arg = copy(a:arg)
    for Func in a:funcs
      let l:arg = Func(l:arg)
    endfor
    return l:arg
  endfunction
  return function("s:compose", [a:funcs])
endfunction

