let func#call# = {}

function! func#call#.wrap(func, arg)
  if type(a:func) == v:t_func
    return a:func(a:arg)
  elseif type(a:func) == v:t_string
    return function(a:func)(a:arg)
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

function! s:until_result(funcs) abort
  function! s:_until_result(funcs, arg)
    unlet! s:result
    for F in a:funcs
      call g:func#call#.wrap(F, a:arg)
      if exists("s:result")
        return s:result
      endif
    endfor
    throw "No result"
  endfunction
  return funcref("s:_until_result", [a:funcs])
endfunction
let func#call#.until_result = func#.list_vararg(funcref("s:until_result"))

function! func#call#.set_result(result)
  let s:result = a:result
endfunction
