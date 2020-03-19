let s:test_suites = {}

function! test#suite(suite_name)
  let s:test_suites[a:suite_name] = {}
  return s:test_suites[a:suite_name]
endfunction
let s:tests = test#suite(expand("<sfile>"))
function! s:tests.suite_should_always_return_new_dict()
  let l:suite = test#suite("suite")
  call assert_equal({}, l:suite)
  let l:suite.some_func = { -> 0 })
  call assert_notequal({}, l:suite)
  let l:suite = test#suite("suite")
  call assert_equal({}, l:suite)
endfunction
function! s:tests.different_suites_should_be_maintained_separately()
  let l:suite_1 = test#suite("suite1")
  let l:suite_2 = test#suite("suite2")
  let l:suite_1.a = { ->  "a" }
  let l:suite_2.b = { ->  "b" }
  call assert_notequal(l:suite_1, l:suite_2)
endfunction

function! s:tests.execute_should_run_all_tests_in_given_suite()
  let l:suite = test#suite("execute")
  let l:results = []
  let l:suite.test1 = { -> add(l:results, 1) }
  let l:suite.test2 = { -> add(l:results, 2) }
  call test#execute("execute")
  call assert_inrange(0, 1, index(l:results, 1))
  call assert_inrange(0, 1, index(l:results, 2))
endfunction
function! test#execute(suite_name)
  let l:script_suite = get(
        \ s:test_suites,
        \ a:suite_name,
        \ {},
        \)
  let v:errors = []
  for func_name in keys(l:script_suite)
    call l:script_suite[func_name]()
  endfor
  echo v:errors
endfunction

" vim:fdm=marker:fmr=function!\ s\:tests.,endfunction
