function! s:compose(funcs) abort
  function! s:_compose(arg) closure abort
    let l:arg = a:arg
    for Func in a:funcs
      let l:arg = call(Func, [l:arg])
    endfor
    return l:arg
  endfunction
  return funcref("s:_compose")
endfunction
function! func#compose(...) abort
  return func#wrap#list_vararg(funcref("s:compose"))(a:000)
endfunction

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
function! func#until_result(...)
  return func#wrap#list_vararg(funcref("s:until_result"))(a:000)
endfunction

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
function! func#call_all(...)
  return func#wrap#list_vararg(funcref("s:all"))(a:000)
endfunction
