let s:test_suites = {}
let s:suite_reports = {}
let s:SUCCESS = 0
let s:FAILED = 1
let s:ERROR = 2

function! test#suite(suite_name)
  let s:test_suites[a:suite_name] = {}
  return s:test_suites[a:suite_name]
endfunction
let s:tests = test#suite(expand("<sfile>:p"))
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
function! s:tests.execute_should_run_all_tests_even_if_there_are_failures()
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
    call s:execute_test(l:script_suite, func_name, l:report)
  endfor
endfunction

function! s:tests.test_execution_should_pass_if_there_are_no_assertions_failures()
  let l:suite_name = "success"
  let l:suite = test#suite(l:suite_name)
  let l:test_func_name = "pass_func"
  let l:suite[l:test_func_name] = { -> v:true }
  let l:report = {}
  call s:execute_test(l:suite, l:test_func_name, l:report)
  let l:test_name = s:format_function_name(l:test_func_name)
  let l:test_report = l:report[l:test_name]
  call assert_equal(s:SUCCESS, l:test_report["result"])
endfunction
function! s:tests.test_execution_should_report_error_if_there_are_test_function_errors()
  let l:suite_name = "error"
  let l:suite = test#suite(l:suite_name)
  let l:test_func_name = "err_func"
  function! s:tests.error()
    call abc()
  endfunction
  let l:suite[l:test_func_name] = { -> s:tests.error() }
  let l:report = {}
  call s:execute_test(l:suite, l:test_func_name, l:report)
  let l:test_name = s:format_function_name(l:test_func_name)
  let l:test_report = l:report[l:test_name]
  call assert_equal(s:ERROR, l:test_report["result"])
  call assert_match("Unknown function: abc", l:test_report["reason"])
endfunction
function! s:tests.test_execution_should_report_failure_if_there_is_assertion_failure()
  let l:suite_name = "fail"
  let l:suite = test#suite(l:suite_name)
  let l:test_func_name = "fail_func"
  function! s:tests.fail() closure
    call assert_true(v:false)
  endfunction
  let l:suite[l:test_func_name] = { -> s:tests.fail() }
  let l:report = {}
  call s:execute_test(l:suite, l:test_func_name, l:report)
  let l:test_name = s:format_function_name(l:test_func_name)
  let l:test_report = l:report[l:test_name]
  call assert_equal(s:FAILED, l:test_report["result"])
  call assert_match("Expected True but got v:false", l:test_report["reason"])
endfunction
function! s:tests.test_execution_should_pass_if_exception_is_expected()
  let l:suite_name = "pass"
  let l:suite = test#suite(l:suite_name)
  let l:test_func_name = "pass_func"
  function! s:tests.exception_assertion()
    function! s:tests.failing()
      throw "Exception"
    endfunction
    try
      call s:tests.failing()
      call assert_true(v:false)
    catch
      call assert_exception("Exception")
    endtry
  endfunction
  let l:suite[l:test_func_name] = { -> s:tests.exception_assertion() }
  let l:report = {}
  call s:execute_test(l:suite, l:test_func_name, l:report)
  let l:test_name = s:format_function_name(l:test_func_name)
  let l:test_report = l:report[l:test_name]
  call assert_equal(s:SUCCESS, l:test_report["result"])
endfunction
function! s:execute_test(test_suite, test_name, suite_report)
  let l:test_report = s:report_add_test(a:suite_report, a:test_name)
  let v:errors = []
  try
    call a:test_suite[a:test_name]()
    if empty(v:errors)
      call s:report_test_success(l:test_report)
    else
      call s:report_test_fail(l:test_report, v:errors)
    endif
  catch
    call s:report_test_error(l:test_report, v:exception)
  finally
    let v:errors = []
  endtry
endfunction

function! s:tests.test_report_should_be_formatted()
  let l:store_suite_reports = copy(s:suite_reports)
  let l:suite_name = "suite"
  let s:suite_reports = {
        \ l:suite_name: {
        \   "pass": { "result": s:SUCCESS },
        \   "fail": {
        \     "result": s:FAILED,
        \     "reason": "Assertion failure",
        \   },
        \   "error": {
        \     "result": s:ERROR,
        \     "reason": "Unknown function",
        \   },
        \ }
        \}
  let l:report = test#report(l:suite_name)
  let l:expected = 'Suite: "'.l:suite_name.'"'."\n".
        \   '  Test: "error"'."\n".
        \   '    [ERROR]: ''Unknown function'''."\n".
        \   '  Test: "fail"'."\n".
        \   '    [FAILED]: ''Assertion failure'''."\n".
        \   '  Test: "pass"'."\n".
        \   '    [PASSED]'."\n".
        \   'Tests executed: 3, passed: 1, failed: 1, errors: 1'
  try
    call assert_equal(l:expected, l:report)
  finally
    let s:suite_reports = l:store_suite_reports
  endtry
endfunction
" TODO refactor
function! test#report(suite_name)
  let l:suite_report = get(s:suite_reports, a:suite_name, {})
  let l:report = []
  call add(l:report, 'Suite: "'.a:suite_name.'"')
  let l:test_names = keys(l:suite_report)
  let l:tests_executed = len(l:test_names)
  let l:tests_passed = 0
  let l:tests_failed = 0
  let l:tests_errored = 0
  for test_name in sort(l:test_names)
    call add(l:report, '  Test: "'.test_name.'"')
    let l:test_report = l:suite_report[l:test_name]
    let l:test_result = l:test_report["result"]
    if l:test_result == s:SUCCESS
      call add(l:report, '    [PASSED]')
      let l:tests_passed += 1
    else
      let l:reason = l:test_report["reason"]
      if l:test_result == s:FAILED
        call add(l:report, '    [FAILED]: '.string(l:reason))
        let l:tests_failed += 1
      elseif l:test_result == s:ERROR
        call add(l:report, '    [ERROR]: '.string(l:reason))
        let l:tests_errored += 1
      endif
    endif
  endfor
  call add(
        \ l:report,
        \ printf(
        \   "Tests executed: %d, passed: %d, failed: %d, errors: %d",
        \   l:tests_executed,
        \   l:tests_passed,
        \   l:tests_failed,
        \   l:tests_errored,
        \ ),
        \)
  return join(l:report, "\n")
endfunction

function! s:tests.format_function_name_replaces_all_underscores_with_spaces()
  let l:func_name = "test_function_1"
  let l:test_name = s:format_function_name(l:func_name)
  call assert_equal("test function 1", l:test_name)
endfunction
function! s:tests.format_function_should_not_changes_name_without_underscores()
  let l:func_name = "testFunction"
  let l:test_name = s:format_function_name(l:func_name)
  call assert_equal(l:func_name, l:test_name)
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
  let a:report["reason"] = a:reasons[-1]
endfunction

function! s:report_test_error(report, reasons)
  let a:report["result"] = s:ERROR
  let a:report["reason"] = a:reasons
endfunction

" vim:fdm=marker:fmr=function!\ s\:tests.,endfunction
