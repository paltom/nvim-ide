let s:script_suites = {}

function! s:get_full_script_file_path(script_path)
  return fnamemodify(findfile(a:script_path, &runtimepath), ":~")
endfunction

function! vut#test_script_file(path)
  let l:full_script_path = s:get_full_script_file_path(a:path)
  let l:script_sid = util#sid(l:full_script_path)
  let l:script_snr = "<snr>".l:script_sid."_"
  let s:script_suites[l:full_script_path] = {
        \ "call_local": function("s:call_local", [l:script_snr])
        \}
  return s:script_suites[l:full_script_path]
endfunction

function! s:call_local(snr, func_name, args)
  return call(a:snr.a:func_name, a:args)
endfunction

let s:reserved_names = [
      \ "call_local",
      \]
function! vut#execute_tests(script_file)
  let l:full_script_path = s:get_full_script_file_path(a:script_file)
  let l:script_suite = get(s:script_suites, l:full_script_path, {})
  execute "source ".l:full_script_path
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
  try
    call s:call_test(a:test_name, a:test_func)
    call s:handle_test_result(a:test_name)
  catch
    call s:handle_test_error(a:test_name)
  finally
    let v:errors = []
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