let func#wrap# = {}

" Wrap a list accepting function so it can also take varargs as arguments
function! func#wrap#.list_vararg(funcref)
  function! s:list_vararg_wrapper(args, ...) closure
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
  return funcref("s:list_vararg_wrapper")
endfunction
