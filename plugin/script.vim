let s:tests = {}
call TestSuite(s:tests)
function! s:tests.functt()
  echomsg "called with ".string(self)
  call assert_equal(s:func_to_test(1, 2), 3, "Equality failed")
  call assert_notequal(2, 2, "Should not be equal")
endfunction
function! s:func_to_test(a, b)
  return a:a + a:b
endfunction
" Can be created with correct script identifier from the outside
"call s:abc()
