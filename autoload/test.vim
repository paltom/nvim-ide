let s:test_suites = {}
let s:suite_reports = {}
let s:SUCCESS = 0
let s:FAILED = 1
let s:ERROR = 2

function! test#suite(suite_name)
  let s:test_suites[a:suite_name] = {}
  return s:test_suites[a:suite_name]
endfunction
let s:tests = test#suite(expand("<sfile>"))
function! s:tests.suite_should_always_return_new_dict()
  let l:suite = test#suite("suite")
  call assert_equal({}, l:suite)
  let l:suite.some_func = { -> v:true }
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
  call execute("call test#execute('execute')", "silent!")
  call assert_inrange(0, 1, index(l:results, 1))
  call assert_inrange(0, 1, index(l:results, 2))
endfunction
function! s:tests.execute_should_run_all_tests_even_there_are_failures()
  let l:suite = test#suite("execute")
  let l:test_calls = 0
  function! s:tests.increment() closure
    let l:test_calls = l:test_calls + 1
  endfunction
  function! s:tests.fail()
    call s:tests.increment()
    throw "Some exception"
  endfunction
  let l:suite.test1 = { -> s:tests.fail() }
  let l:suite.test2 = { -> s:tests.fail() }
  call execute("call test#execute('execute')", "silent!")
  call assert_equal(
        \ 2,
        \ l:test_calls,
        \ "Failing function should be called twice"
        \)
endfunction
function! test#execute(suite_name)
  let l:script_suite = get(
        \ s:test_suites,
        \ a:suite_name,
        \ {},
        \)
  let l:report = {}
  let s:suite_reports[a:suite_name] = l:report
  for func_name in sort(keys(l:script_suite))
    let l:test_report = s:report_add_test(l:report, func_name)
    let v:errors = []
    try
      call l:script_suite[func_name]()
      if empty(v:errors)
        call s:report_test_success(l:test_report)
      else
        call s:report_test_fail(l:test_report, v:errors)
      endif
    catch
      call s:report_test_error(l:test_report, v:exception)
    finally
    endtry
  endfor
endfunction

function! test#report(suite_name)
  return get(s:suite_reports, a:suite_name, {})
endfunction

function! s:format_function_name(func_name)
  " simply replace '_' with spaces
  return substitute(a:func_name, "_", " ", "g")
endfunction

function! s:report_add_test(report, test_name)
  let l:test_name = s:format_function_name(a:test_name)
  let a:report[l:test_name] = {}
  return a:report[l:test_name]
endfunction

function! s:report_test_success(report)
  let a:report["result"] = s:SUCCESS
endfunction

function! s:report_test_fail(report, reasons)
  let a:report["result"] = s:FAILED
  let a:report["reason"] = a:reasons
endfunction

function! s:report_test_error(report, reasons)
  let a:report["result"] = s:ERROR
  let a:report["reason"] = a:reasons
endfunction

" vim:fdm=marker:fmr=function!\ s\:tests.,endfunction
