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
      if type(Func) == v:t_func
        let l:arg = Func(l:arg)
      elseif type(Func) == v:t_string
        let l:arg = function(Func)(l:arg)
      endif
    endfor
    return l:arg
  endfunction
  " create composed function waiting for arg (partial)
  return funcref("s:comp", [a:funcs])
endfunction
let func#.compose = func#.list_vararg(funcref("s:compose"))
