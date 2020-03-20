" TODO: report structure for test instead of messages list
" - to control in render functions how report is created
let s:test_suites = {}
let s:suite_reports = {}

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
function! s:tests.execute_should_report_suite_name()
  let l:suite_name = "suite name"
  let l:suite = test#suite(l:suite_name)
  let l:suite.test_function = { -> v:true }
  call execute("call test#execute('".l:suite_name."')", "silent!")
  call assert_equal(
        \ 0,
        \ index(
        \   s:suite_reports[l:suite_name]["messages"],
        \   'Executing suite: "'.l:suite_name.'"'
        \ ),
        \ "Suite name should be first entry in report",
        \)
endfunction
function! s:tests.execute_should_report_executed_test_name()
  let l:suite_name = "test_name"
  let l:suite = test#suite(l:suite_name)
  let l:suite.test_function_name = { -> v:true }
  call execute("call test#execute('".l:suite_name."')", "silent!")
  call assert_true(
        \ index(
        \   s:suite_reports[l:suite_name]["messages"],
        \   'Executing test: "test function name"'
        \ ) > 0,
        \ "Test name should be in report"
        \)
endfunction
function! test#execute(suite_name)
  let l:script_suite = get(
        \ s:test_suites,
        \ a:suite_name,
        \ {},
        \)
  let l:report = s:new_report()
  let s:suite_reports[a:suite_name] = l:report
  call s:report_msg_suite_start(l:report, a:suite_name)
  for func_name in sort(keys(l:script_suite))
    call s:report_msg_test_start(l:report, func_name)
    let v:errors = []
    try
      call l:script_suite[func_name]()
      if empty(v:errors)
        call s:report_test_success(l:report)
      else
        call s:report_test_fail(l:report, v:errors)
      endif
    catch
      echohl ErrorMsg
      echomsg "ERROR:".string(v:exception)
      echohl None
    finally
    endtry
  endfor
endfunction

function! test#report(suite_name)
  return join(get(s:suite_reports[a:suite_name], "messages", []), "\n")
endfunction

function! s:format_function_name(func_name)
  " simply replace '_' with spaces
  return substitute(a:func_name, "_", " ", "g")
endfunction

function! s:report_msg_suite_start(report, suite_name)
  call add(a:report["messages"], 'Executing suite: "'.a:suite_name.'"')
endfunction

function! s:report_msg_test_start(report, test_name)
  let l:test_name = s:format_function_name(a:test_name)
  call add(a:report["messages"], 'Executing test: "'.l:test_name.'"')
  let a:report["executed"] += 1
endfunction

function! s:report_test_success(report)
  " add [SUCCESS] under last message (name of last test executed)
  call add(a:report["messages"], "[SUCCESS]")
  let a:report["passed"] += 1
endfunction

function! s:report_test_fail(report, reasons)
  " add [FAILED ] under last message (name of last test executed)
  call add(a:report["messages"], "[FAILED ]".string(a:reasons))
  let a:report["failed"] += 1
endfunction

function! s:report_test_error(report, reasons)
  " add [ ERROR ] under last message (name of last test executed)
  call add(a:report["messages"], "[ ERROR ]")
  let a:report["errors"] += 1
endfunction

function! s:new_report()
  return {
        \ "executed": 0,
        \ "passed": 0,
        \ "failed": 0,
        \ "errors": 0,
        \ "messages": []
        \}
endfunction

" vim:fdm=marker:fmr=function!\ s\:tests.,endfunction
