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
        \ ["silent 4 verbose 3, 5 TestCmd! a Test b ", ["a", "Test", "b"]],
        \]
  for data in l:data
    call assert_equal(
          \ data[1],
          \ self.call_local("cmdline_command_args", [data[0]])
          \)
  endfor
endfunction

function! s:tests.cmdline_parse_command_name_and_args()
  let l:data = [
        \ ["TestCmd" ,["TestCmd", []]],
        \ ["TestCmd Test", ["TestCmd", ["Test"]]],
        \ ["TestCmd a b c", ["TestCmd", ["a", "b", "c"]]],
        \ ["silent 4 verbose 3, 5 TestCmd! a Test b", ["TestCmd", ["a", "Test", "b"]]],
        \]
  for data in l:data
    call self.call_local("cmdline_parse", [data[0]])
    call assert_equal(
          \ data[1],
          \ self.call_local("get_cmdline_tokens", [])
          \)
  endfor
endfunction

function! s:tests.get_menu_by_path()
  let l:menu = [
        \ {
        \   "cmd": "Flat",
        \ },
        \ {
        \   "cmd": "FirstLevel",
        \   "menu": [
        \     {
        \       "cmd": "SecondLevel",
        \     },
        \   ],
        \ },
        \ {
        \   "cmd": "EmptyMenu",
        \   "menu": [],
        \ },
        \]
  let l:data = [
        \ [[], [{}, []]],
        \ [["F"], [{}, ["F"]]],
        \ [["Flat"], [{"cmd": "Flat"}, []]],
        \]
  for data in l:data
    call assert_equal(
          \ data[1],
          \ self.call_local("get_cmd_obj_by_path", [l:menu, data[0]]),
          \)
  endfor
endfunction

function! s:tests.update_commands_creates_commands_based_on_top_level_menu()
  let g:cmdmenu = self.mock_var("g:cmdmenu")
  let g:cmdmenu[1] = "abc"
endfunction

" TODO: should be loaded by ftplugin (special filetype inheriting from vim)
command! -buffer Test w<bar>so %<bar>call vut#execute_tests(s:script_to_test)
" vim:fdm=indent
