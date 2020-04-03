let func#wrap# = {}

" Wrap a list accepting function so it can also take varargs as arguments
function! s:list_vararg_wrapper(funcref, args, ...)
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
function! func#wrap#.list_vararg(funcref)
  return funcref("s:list_vararg_wrapper", [a:funcref])
endfunction

" Wrap a function, so it can accept any number of arguments
" Useful for HOF functions calling multiple functions, so the don't need to
" worry about functions arguments
function! s:vararg_wrapper(funcref, ...)
  return function(a:funcref, a:000)()
endfunction
function! func#wrap#.vararg(funcref)
  return funcref("s:vararg_wrapper", [a:funcref])
endfunction

" Wrap a function, so it can be called either by funcref or by name (must be
" globally visible)
" Useful for for HOFs, so we can pass functions easily
function! func#wrap#.funcref_string(func, arg)
  if type(a:func) == v:t_func
    return a:func(a:arg)
  elseif type(a:func) == v:t_string
    return function(a:func)(a:arg)
  endif
endfunction
