let func# = {}

function! s:_compose(funcs, arg)
  let l:arg = a:arg
  for Func in a:funcs
    let l:arg = g:func#wrap#.funcref_string(Func, l:arg)
  endfor
  return l:arg
endfunction
function! s:compose(funcs)
  " create composed function waiting for single arg (partial)
  return funcref("s:_compose", [a:funcs])
endfunction
let func#.compose = func#wrap#.list_vararg(funcref("s:compose"))

function! s:_until_result(funcs, arg)
  for F in a:funcs
    let l:result = g:func#wrap#.funcref_string(F, a:arg)
    if l:result isnot# v:null
      return l:result
    endif
  endfor
  return v:null
endfunction
function! s:until_result(funcs) abort
  return g:func#wrap#.vararg(funcref("s:_until_result", [a:funcs]))
endfunction
let func#.until_result = func#wrap#.list_vararg(funcref("s:until_result"))

function! s:_all(funcs, arg)
  let l:results = []
  for F in a:funcs
    let l:results = add(l:results, g:func#wrap#.funcref_string(F, a:arg))
  endfor
  return l:results
endfunction
function! s:all(funcs)
  return g:func#wrap#.vararg(funcref("s:_all", [a:funcs]))
endfunction
let func#.call_all = func#wrap#.list_vararg(funcref("s:all"))
