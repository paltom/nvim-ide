let func# = {}

" Wrap a list accepting function so it can also take varargs as arguments
" This is just for convenience
function! func#.list_vararg(funcref)
  function! s:wrapper(args, ...) closure
    if a:0 == 0
      if type(a:args) == v:t_list
        let l:args = a:args
      else
        let l:args = [a:args]
      endif
    elseif a:0 > 0
      let l:args = extend([a:args], a:000)
    endif
    return a:funcref(l:args)
  endfunction
  return funcref("s:wrapper")
endfunction

function! s:compose(funcs)
  function! s:comp(funcs, arg)
    let l:arg = a:arg
    for Func in a:funcs
      let l:arg = g:func#call#.wrap(Func, l:arg)
    endfor
    return l:arg
  endfunction
  " create composed function waiting for arg (partial)
  return funcref("s:comp", [a:funcs])
endfunction
let func#.compose = func#.list_vararg(funcref("s:compose"))

function! s:until_result(funcs) abort
  function! s:_until_result(funcs, arg)
    for F in a:funcs
      let l:result = g:func#call#.wrap(F, a:arg)
      if l:result isnot# v:null
        return l:result
      endif
    endfor
    throw "No result"
  endfunction
  return funcref("s:_until_result", [a:funcs])
endfunction
let func#.until_result = func#.list_vararg(funcref("s:until_result"))
