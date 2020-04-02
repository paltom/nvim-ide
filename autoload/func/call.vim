let func#call# = {}

function! func#call#.wrap(func, arg)
  if type(a:func) == v:t_func
    return a:func(a:arg)
  elseif type(a:func) == v:t_string
    return function(a:func)(l:arg)
  endif
endfunction

function! s:all(funcs)
  function! s:_all(funcs, arg)
    let l:results = []
    for F in a:funcs
      let l:results = add(l:results, g:func#call#.wrap(F, a:arg))
    endfor
    return l:results
  endfunction
  return funcref("s:_all", [a:funcs])
endfunction
let func#call#.all = func#.list_vararg(funcref("s:all"))
