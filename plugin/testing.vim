function! TestSuite(suite)
  let s:suite = a:suite
endfunction

function! Test()
  if !exists(s:suite)
    return
  endif
  let v:errors = []
  for test in keys(s:suite)
    let TestFn = s:suite[test]
    call TestFn()
  endfor
endfunction
