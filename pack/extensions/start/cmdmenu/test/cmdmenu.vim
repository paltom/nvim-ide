let s:script_to_test = "autoload/cmdmenu.vim"
let s:tests = vut#test_script_file(s:script_to_test)

function! s:tests.cmdline_parse_get_command_name()
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
          \ self.call_local("cmdline_command_name", [cmdline])
          \)
  endfor
endfunction

function! s:tests.cmdline_parse_get_command_args()
  let l:data = [
        \ ["TestCmd", []],
        \ ["TestCmd Test", ["Test"]],
        \ ["TestCmd a b c", ["a", "b", "c"]],
        \ ["silent 4 verbose 3, 5 TestCmd! a Test b", ["a", "Test", "b"]],
        \]
  for cmdline in l:data
    call assert_equal(
          \ cmdline[1],
          \ self.call_local("cmdline_command_args", [cmdline[0]])
          \)
  endfor
endfunction

command! -buffer Test w<bar>so %<bar>call vut#execute_tests(s:script_to_test)
