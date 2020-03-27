let s:tested_file = "autoload/cmdmenu.vim"
let s:script_path = fnamemodify(findfile(s:tested_file, &runtimepath), ":~")
function! s:map(func) " to be moved to func#
  function! s:_map(func, list)
    let l:list = copy(a:list)
    let l:list = map(l:list, a:func)
    return l:list
  endfunction
  return function("s:_map", [a:func])
endfunction
function! s:filter(func) " to be moved to func#
  function! s:_filter(func, list)
    let l:list = copy(a:list)
    let l:list = filter(l:list, a:func)
    return l:list
  endfunction
  return function("s:_filter", [a:func])
endfunction
function! s:compose(funcs) " to be moved to func#
  function! s:_compose(funcs, arg)
    let l:arg = copy(a:arg)
    for Func in a:funcs
      let l:arg = Func(l:arg)
    endfor
    return l:arg
  endfunction
  return function("s:_compose", [a:funcs])
endfunction
function! s:get_sid(script_path) " to be moved to utils#
  let l:scriptnames = s:compose([
        \ s:map({ _, name -> split(name, ": ") }),
        \ s:map({ _, entry -> [str2nr(trim(entry[0])), trim(entry[1])] }),
        \])
        \(split(execute("scriptnames"), "\n"))
  let l:match = s:filter({ _, entry -> entry[1] ==# a:script_path })
        \(l:scriptnames)
  if len(l:match) != 1
    return 0
  else
    return l:match[0][0]
  endif
endfunction

execute "source ".s:script_path
let s:sid = s:get_sid(s:script_path)
let s:snr = "<snr>".s:sid."_"
function! s:call_local(func_name, args)
  return call(s:snr.a:func_name, a:args)
endfunction

" ==============================================================================

let s:tests = {}
let s:tests.cmdline_parse = {}

function! s:tests.cmdline_parse.get_command_name()
  let l:data = [
        \ "TestCmd",
        \ " TestCmd ",
        \ "TestCmd!",
        \ "3TestCmd",
        \ "1,4 TestCmd",
        \ "TestCmd a b c",
        \ "TestCmd Test Cmd",
        \ "silent 4verbose 3,5 TestCmd! Test a b c",
        \ "silent 4 verbose 3, 5 TestCmd! a Test b",
        \]
  for cmdline in l:data
    call assert_equal(
          \ "TestCmd",
          \ s:call_local("cmdline_command_name", [cmdline])
          \)
  endfor
endfunction

function! s:tests.cmdline_parse.get_command_args()
  let l:data = [
        \ ["TestCmd", []],
        \ ["TestCmd Test", ["Test"]],
        \ ["TestCmd a b c", ["a", "b", "c"]],
        \ ["silent 4 verbose 3, 5 TestCmd! a Test b", ["a", "Test", "b"]],
        \]
  for cmdline in l:data
    call assert_equal(
          \ cmdline[1],
          \ s:call_local("cmdline_command_args", [cmdline[0]])
          \)
  endfor
endfunction

" ==============================================================================

for test in keys(s:tests)
  let s:cases = s:tests[test]
  for case in keys(s:cases)
    let v:errors = []
    try
      echomsg "Executing ".test.".".case
      call s:cases[case]()
      if empty(v:errors)
        " passed
      else
        for error in v:errors
          echomsg "Test ".test.".".case." FAILED: ".string(error)
        endfor
      endif
    catch
      echohl ErrorMsg
      echomsg "Test ".test.".".case." ERROR: ".string(v:exception)." @ ".string(v:throwpoint)
      echohl None
    finally
      let v:errors = []
    endtry
  endfor
endfor

