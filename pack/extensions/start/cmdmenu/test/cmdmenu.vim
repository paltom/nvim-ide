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

function! s:tests.cmdline_parse_sets_tokens()
  let l:data = [
        \ ["TestCmd" ,{"cmd": "TestCmd", "args": [], "pos": 7}],
        \ ["TestCmd Test", {"cmd": "TestCmd", "args": ["Test"], "pos": 12}],
        \ ["TestCmd a b c", {"cmd": "TestCmd", "args": ["a", "b", "c"], "pos": 13}],
        \ ["silent 4 verbose 3, 5 TestCmd! a Test b", {"cmd": "TestCmd", "args": ["a", "Test", "b"], "pos": 39}],
        \]
  for data in l:data
    call self.call_local("cmdline_parse", [data[0], len(data[0])])
    call assert_equal(
          \ data[1],
          \ self.call_local("get_cmdline_tokens", [])
          \)
  endfor
endfunction

function! s:tests.cmdline_parse_parses_automatically_while_command_is_being_entered()
  let l:command = "TestCommand a b c"
  let l:mock = self.mock_local_func("cmdline_parse")
  for cmdline_end in range(len(l:command))
    let l:mock["calls"] = []
    silent execute "normal! :".l:command[0:cmdline_end]
    call assert_equal(
          \ cmdline_end + 1,
          \ l:mock["call_count"],
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
        \ [["Fl"], [{"cmd": "Flat"}, []]],
        \ [["Fir"], [{"cmd": "FirstLevel", "menu": [{"cmd": "SecondLevel"}]}, []]],
        \ [["EmptyMenu"], [{"cmd": "EmptyMenu", "menu": []}, []]],
        \ [["None"], [{}, ["None"]]],
        \ [["Fl", "a", "b", "c"], [{"cmd": "Flat"}, ["a", "b", "c"]]],
        \ [["First", "Second", "other"], [{"cmd": "SecondLevel"}, ["other"]]],
        \ [["Fir", "other"], [{"cmd": "FirstLevel", "menu": [{"cmd": "SecondLevel"}]}, ["other"]]],
        \]
  for data in l:data
    call assert_equal(
          \ data[1],
          \ self.call_local("get_cmd_obj_by_path", [l:menu, data[0]]),
          \)
  endfor
endfunction

function! s:tests.update_commands_creates_commands_based_on_top_level_menu()
  call self.mock_var("g:cmdmenu")
  let l:commands = [
        \ "TestCommand1",
        \ "TestCommand2",
        \]
  let l:nested_commands = [
        \ "Nested1",
        \ "Nested2",
        \]
  let g:cmdmenu = func#map(
        \ { i, c -> {"cmd": c, "menu": l:nested_commands[i]} },
        \)
        \(l:commands)
  call cmdmenu#update_commands()
  for cmd in l:commands
    call assert_equal(
          \ 2,
          \ exists(":".cmd)
          \)
  endfor
  for nested in l:nested_commands
    call assert_equal(
          \ 0,
          \ exists(":".nested)
          \)
  endfor
  " cleanup after test
  for cmd in l:commands
    execute "delcommand ".cmd
  endfor
endfunction

function! s:tests.update_command_creates_command_passing_any_number_of_args()
  let l:command = "TestCommand"
  call self.call_local("update_command", [l:command])
  let l:execute_cmd_mock = self.mock_local_func("execute_cmd")
  let l:data = [
        \ ["", []],
        \ ["a", ["a"]],
        \ ["b c 13", ["b", "c", "13"]],
        \]
  for row in l:data
    execute l:command." ".row[0]
  endfor
  call assert_equal(
        \ len(l:data),
        \ l:execute_cmd_mock["call_count"],
        \)
  for idx in range(len(l:data))
    let l:entry = l:data[idx]
    call assert_equal(
          \ l:entry[1],
          \ l:execute_cmd_mock["calls"][idx]["args"][2],
          \)
  endfor
  execute "delcommand ".l:command
endfunction

function! s:tests.update_command_creates_command_passing_bang_flag()
  let l:command = "TestCommand"
  call self.call_local("update_command", [l:command])
  let l:execute_cmd_mock = self.mock_local_func("execute_cmd")
  let l:data = [
        \ ["", v:false],
        \ ["!", v:true],
        \]
  for entry in l:data
    execute l:command.entry[0]
  endfor
  call assert_equal(
        \ len(l:data),
        \ l:execute_cmd_mock["call_count"],
        \)
  for idx in range(len(l:data))
    let l:entry = l:data[idx]
    if l:entry[1]
      let l:assert = "true"
    else
      let l:assert = "false"
    endif
    execute "call assert_".l:assert."(".
          \   "l:execute_cmd_mock['calls'][idx]['args'][1]".
          \ ")"
  endfor
  execute "delcommand ".l:command
endfunction

function! s:tests.update_command_creates_command_passing_range()
  let l:command = "TestCommand"
  call self.call_local("update_command", [l:command])
  let l:execute_cmd_mock = self.mock_local_func("execute_cmd")
  call setpos(".", [0, 1, 1, 0])
  let l:data = [
        \ ["", [line("."), line(".")]],
        \ ["2", [2, 2]],
        \ ["3, 4", [3, 4]],
        \]
  for entry in l:data
    execute entry[0].l:command
  endfor
  call assert_equal(
        \ len(l:data),
        \ l:execute_cmd_mock["call_count"],
        \)
  for idx in range(len(l:data))
    let l:entry = l:data[idx][1]
    call assert_equal(
          \ l:entry,
          \ l:execute_cmd_mock["calls"][idx]["range"],
          \)
  endfor
  execute "delcommand ".l:command
endfunction

function! s:tests.execute_cmd_executes_function_associates_with_cmd_object()
  let l:command = "TestCommand"
  call self.mock_var("g:cmdmenu")
  let l:action_args = []
  function! s:fail(args, flag, mods)
    throw "Should not be called"
  endfunction
  let g:cmdmenu = [
        \ {
        \   "cmd": "TestCommand",
        \   "menu": [
        \     {
        \       "cmd": "a",
        \       "menu": [
        \         {
        \           "cmd": "b",
        \           "action": { a, f, m -> extend(l:action_args, [a, f, m]) },
        \           "menu": [
        \             {
        \               "cmd": "c",
        \               "action": function("s:fail"),
        \             },
        \           ],
        \         },
        \       ],
        \     },
        \   ],
        \ },
        \]
  call cmdmenu#update_commands()
  silent execute l:command." a b"
  call assert_equal(
        \ [[], v:false, "silent"],
        \ l:action_args,
        \)
  let l:action_args = []
  execute "normal! :".l:command." a\<cr>"
  call assert_equal(
        \ [],
        \ l:action_args,
        \)
  let l:last_message = trim(execute("1messages"))
  execute "1messages clear"
  call assert_equal(
        \ "No action for this command",
        \ l:last_message,
        \)
  execute "delcommand TestCommand"
endfunction

" TODO: should be loaded by ftplugin (special filetype inheriting from vim)
command! -buffer Test w<bar>so %<bar>call vut#execute_tests(s:script_to_test)
" vim:fdm=indent
