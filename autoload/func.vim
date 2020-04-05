let func# = {}

function! s:compose(funcs)
  function! s:_compose(arg) closure
    let l:arg = a:arg
    for Func in a:funcs
      let l:arg = call(Func, [l:arg])
    endfor
    return l:arg
  endfunction
  return funcref("s:_compose")
endfunction
let func#.compose = func#wrap#.list_vararg(funcref("s:compose"))

function! s:until_result(funcs)
  function! s:_until_result(...) closure
    for F in a:funcs
      let l:result = call(F, a:000)
      if l:result isnot# v:null
        return l:result
      endif
    endfor
    return v:null
  endfunction
  return funcref("s:_until_result")
endfunction
let func#.until_result = func#wrap#.list_vararg(funcref("s:until_result"))

function! s:all(funcs)
  function! s:_all(...) closure
    let l:results = []
    for F in a:funcs
      let l:results = add(l:results, call(F, a:000))
    endfor
    return l:results
  endfunction
  return funcref("s:_all")
endfunction
let func#.call_all = func#wrap#.list_vararg(funcref("s:all"))
