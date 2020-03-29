let s:script_suites = {}

function! vut#test_script_file(path)
  let l:full_script_path = util#get_full_script_file_path(a:path)
  execute "source ".l:full_script_path
  let l:script_sid = util#sid(l:full_script_path)
  let l:script_snr = "<SNR>".l:script_sid."_"
  let s:script_suites[l:full_script_path] = {
        \ "call_local": function("s:call_local", [l:script_snr]),
        \ "mock_var": function("s:mock_var"),
        \ "mock_local_func": function("s:mock_local_func", [l:script_snr]),
        \}
  return s:script_suites[l:full_script_path]
endfunction

function! s:call_local(snr, func_name, args)
  return call(a:snr.a:func_name, a:args)
endfunction

let s:mocks_var = []
function! s:mock_var(var_name)
  if !exists(a:var_name)
    return
  endif
  execute "let l:value = ".a:var_name
  let s:mock_var = add(
        \ s:mocks_var,
        \ {
        \   "name": a:var_name,
        \   "value": l:value,
        \ },
        \)
  execute "let ".a:var_name." = deepcopy(l:value)"
endfunction

let s:mocks_local_func = {}
let s:MOCKED = 1
let s:CREATED = 2
function! s:mock_local_func(snr, func_name)
  let l:func_name = a:snr.a:func_name
  let l:mock = {
        \ "calls": [],
        \ "call_count": 0,
        \ "return_value": 0,
        \}
  function! s:mock_call(args) closure
    let l:mock.calls = add(l:mock.calls, a:args)
    let l:mock.call_count = len(l:mock.calls)
    return l:mock.return_value
  endfunction
  if exists("*".l:func_name)
    let s:mocks_local_func[l:func_name] = s:MOCKED
  else
    let s:mocks_local_func[l:func_name] = s:CREATED
  endif
  execute "function! ".l:func_name."(...) range\n".
        \   "let l:args = {'range': [a:firstline, a:lastline], 'args': copy(a:000)}\n".
        \   "return s:mock_call(l:args)\n".
        \ "endfunction"
  return l:mock
endfunction

let s:reserved_names = [
      \ "call_local",
      \ "mock_var",
      \ "mock_local_func",
      \]
function! vut#execute_tests(script_file)
  let l:full_script_path = util#get_full_script_file_path(a:script_file)
  let l:script_suite = get(s:script_suites, l:full_script_path, {})
  for test in func#compose([
        \ { _ -> keys(_) },
        \ func#filter({ _, name -> !func#contains(s:reserved_names)(name) }),
        \ { _ -> sort(_) },
        \])
        \(l:script_suite)
    call s:execute_test(test, l:script_suite[test])
  endfor
endfunction

function! s:execute_test(test_name, test_func)
  let v:errors = []
  let l:curpos = getcurpos()
  try
    call s:call_test(a:test_name, a:test_func)
    call s:handle_test_result(a:test_name)
  catch
    call s:handle_test_error(a:test_name)
  finally
    call setpos(".", l:curpos)
    call s:cleanup()
  endtry
endfunction

function! s:call_test(name, func)
  echomsg "Executing ".a:name
  call a:func()
endfunction

function! s:handle_test_result(name)
  if empty(v:errors)
    " test passed
  else
    for error in v:errors
      echomsg "Test '".a:name."' FAILED: ".string(error)
    endfor
  endif
endfunction

function! s:handle_test_error(name)
  echohl ErrorMsg
  echomsg "Test '".a:name."' ERROR: ".
        \ string(v:exception)." @ ".string(v:throwpoint)
  echohl None
endfunction

function! s:cleanup()
  let v:errors = []
  call s:unmock_vars()
  call s:unmock_funcs()
endfunction

function! s:unmock_vars()
  for mock_var in s:mocks_var
    call s:set_var(
          \ mock_var["name"],
          \ mock_var["value"],
          \)
  endfor
  let s:mocks_var = []
endfunction

function! s:set_var(name, value)
  execute "let ".a:name." = a:value"
endfunction

function! s:unmock_funcs()
  for func_name in keys(s:mocks_local_func)
    let l:mock_type = s:mocks_local_func[func_name]
    execute "delfunction ".func_name
    if l:mock_type == s:MOCKED
      let l:script = util#script_by_sid(matchstr(func_name, '\v\<SNR\>\zs\d+\ze'))
      execute "source ".l:script
    endif
  endfor
  let s:mocks_local_func = {}
endfunction
