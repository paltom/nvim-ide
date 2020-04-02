let func#call# = {}

function! s:all(funcs)
  function! s:_all(funcs, arg)
    let l:results = []
    for F in a:funcs
      let l:results = add(l:results, F(a:arg))
    endfor
    return l:results
  endfunction
  return funcref("s:_all", [a:funcs])
endfunction
let func#call#.all = func#.list_vararg(funcref("s:all"))
