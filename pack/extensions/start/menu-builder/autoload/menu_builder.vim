" Menu builder plugin for building custom menu trees as Vim commands with
" arguments.
"
" Data type:
" cmd_object - Dictionary with following keys:
"   - exec - (String|Funcref) Action to execute when cmd object is invoked
"            from cmdline. Optional, mandatory if there is no menu attribute
"            in cmd object.
"
"            String action:
"            - is executed as Vim command (:help :execute)
"            - if menu command was invoked with bang flag, it is passed to the
"            first command in String action.
"            Example:
"
"               "exec": "w|echo 2"
"
"               if invoked with bang flag, action will be invoked as
"               "w!|echo 2"
"           - if menu command was invoked with range, first command in String
"           action will be executed with same range.
"           Example:
"
"               "exec": "s/a/b/|echo 2"
"
"               if invoked with 1,3 range, action will be invoked as
"               "1,3s/a/b/|echo 2"
"           - if menu command was invoked with additional arguments not
"           consumed by menu path, first command will be invoked with
"           additional arguments converted to strings and quoted.
"           Example:
"
"               "exec": "echo"
"
"               if invoked with additional arguments "abc 123", action will
"               be invoked as
"               "echo 'abc' '123'"
"
"           Funcref action:
"           - action function must accept following arguments:
"             1. list of additional arguments passed to cmd object
"             2. boolean flag indicating if bang was used to invoke menu
"             command
"             3. list containing 0, 1 or 2 ints indicating range with which
"             menu command was invoked
"             4. string of command modifiers (:help <mods>)
"           - action function defines its own way of handling arguments passed
"           and it does not need to consume them all
"           - result from action function is discarded

if !exists("g:menus")
  let g:menus = []
endif

" test suite object
let s:tests = test#suite(expand("%:p"))
" test helper functions
function! s:tests._is_full_command(name) " {{{1
  let l:result = exists(":".a:name)
  return l:result == 2
endfunction " }}}

" =============================================================================

function! s:cmd_names_in_menu(menu)
  return map(
        \ copy(a:menu),
        \ { _, cmd_obj -> cmd_obj["cmd"] },
        \)
endfunction

function! s:get_cmd_obj_from_menu(menu, cmd_name)
  let l:cmd_obj = filter(
        \ copy(a:menu),
        \ { _, cmd_obj -> cmd_obj["cmd"] ==# a:cmd_name },
        \)
  if empty(l:cmd_obj)
    return {}
  else
    return l:cmd_obj[0]
  endif
endfunction

function! s:get_all_names_matching_prefix(names, prefix)
  return filter(
        \ copy(a:names),
        \ { _, name -> name =~# '\v^'.a:prefix },
        \)
endfunction

function! s:tests.find_by_prefix_single_returns_name_matching_prefix_unambiguously() " {{{1
  let l:names = [
        \ "name_abc",
        \ "name_def",
        \]
  let l:name_prefix = "name_d"
  let l:name_found = s:find_by_prefix_single(l:names, l:name_prefix)
  call assert_equal("name_def", l:name_found)
endfunction
function! s:tests.find_by_prefix_single_returns_empty_string_when_no_or_multiple_matches_found() " {{{1
  let l:names = [
        \ "name_abc",
        \ "name_def",
        \]
  let l:name_prefix = "test"
  let l:name_found = s:find_by_prefix_single(l:names, l:name_prefix)
  call assert_equal("", l:name_found)
  let l:name_prefix = "name"
  let l:name_found = s:find_by_prefix_single(l:names, l:name_prefix)
  call assert_equal("", l:name_found)
endfunction
function! s:tests.find_by_prefix_single_returns_exact_match_when_multiple_matches_found() " {{{1
  let l:names = [
        \ "name_abc",
        \ "name_def",
        \ "name",
        \]
  let l:name_prefix = "name"
  let l:name_found = s:find_by_prefix_single(l:names, l:name_prefix)
  call assert_equal("name", l:name_found)
endfunction
" }}}
function! s:find_by_prefix_single(names, name)
  let l:names_matching_prefix = s:get_all_names_matching_prefix(a:names, a:name)
  if !empty(l:names_matching_prefix)
    if len(l:names_matching_prefix) == 1
      return l:names_matching_prefix[0]
    endif
    let l:exact_match = filter(
          \ l:names_matching_prefix,
          \ { _, name -> name ==# a:name },
          \)
    if !empty(l:exact_match)
      return l:exact_match[0]
    endif
  endif
  return ""
endfunction

function! s:tests.update_menu_commands_creates_new_commands_for_all_menus() " {{{1
  let l:menus = copy(g:menus)
  let l:menu_names = [
        \ "TestCommand",
        \ "TestName",
        \]
  let g:menus = map(
        \ copy(l:menu_names),
        \ { _, name -> {"cmd": name} }
        \)
  call menu_builder#update_menu_commands()
  for cmd_name in l:menu_names
    call assert_true(s:tests._is_full_command(cmd_name))
  endfor
  for cmd_name in l:menu_names
    execute "delcommand ".cmd_name
  endfor
  let g:menus = l:menus
endfunction
" }}}
function! menu_builder#update_menu_commands()
  for menu_name in s:cmd_names_in_menu(g:menus)
    call s:update_menu_command(menu_name)
  endfor
endfunction

function! s:tests.update_menu_command_given_cmd_name() " {{{1
  let l:cmd_name = "TestCommand"
  call s:update_menu_command(l:cmd_name)
  call assert_true(s:tests._is_full_command(l:cmd_name))
  execute "delcommand ".l:cmd_name
endfunction
function! s:tests.update_menu_command_fails_on_invalid_name() " {{{1
  let l:cmd_name = "test"
  try
    call s:update_menu_command(l:cmd_name)
  catch
    call assert_exception('E183:')
  endtry
  let l:cmd_name = "te:st"
  try
    call s:update_menu_command(l:cmd_name)
  catch
    call assert_exception('E182:')
  endtry
endfunction
" }}}
function! s:update_menu_command(cmd)
  let l:command_func_args = [
        \ "<bang>v:false",
        \ "<range>?[<line1>,<line2>][0:<range>-1]:[]",
        \ "split(<q-args>)",
        \ "<q-mods>",
        \]
  let l:command_func_args = join(l:command_func_args, ", ")
  let l:command_def = [
        \ "command!",
        \ "-nargs=*",
        \ "-complete=custom,s:complete_menu_cmd",
        \ "-range",
        \ "-bang",
        \ "-bar",
        \ a:cmd,
        \ "call s:invoke_menu_command(",
        \ l:command_func_args,
        \ ")",
        \]
  let l:command_def = join(l:command_def, " ")
  execute l:command_def
endfunction

function! s:tests.find_cmd_obj_returns_cmd_object_in_flat_menu_structure() " {{{1
  let l:menu = [
        \ {
        \   "cmd": "TestCommand",
        \ },
        \ {
        \   "cmd": "OtherCommand",
        \ }
        \]
  let l:cmd_path = ["TestCommand"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal([{"cmd": "TestCommand"}, []], l:cmd_obj)
endfunction
function! s:tests.find_cmd_obj_returns_empty_dict_if_no_cmd_obj_found() " {{{1
  let l:menu = [
        \ {
        \   "cmd": "TestCommand",
        \ },
        \ {
        \   "cmd": "OtherCommand",
        \ }
        \]
  let l:cmd_path = ["LookForMe"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal([{}, ["LookForMe"]], l:cmd_obj)
endfunction
function! s:tests.find_cmd_obj_returns_empty_dict_if_no_path_given() " {{{1
  let l:menu = [
        \ {
        \   "cmd": "TestCommand",
        \ },
        \ {
        \   "cmd": "OtherCommand",
        \ }
        \]
  let l:cmd_path = []
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal([{}, []], l:cmd_obj)
endfunction
function! s:tests.find_cmd_obj_returns_cmd_object_matching_prefix() " {{{1
  let l:menu = [
        \ {
        \   "cmd": "TestCommand",
        \ },
        \ {
        \   "cmd": "TestMenu",
        \ }
        \]
  let l:cmd_path = ["TestC"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal([{"cmd": "TestCommand"}, []], l:cmd_obj)
endfunction
function! s:tests.find_cmd_obj_returns_cmd_object_in_nested_menu_structure() " {{{1
  let l:menu = [
        \ {
        \   "cmd": "level1",
        \   "menu": [
        \     {
        \       "cmd": "test",
        \     },
        \   ]
        \ },
        \ {
        \   "cmd": "test",
        \   "menu": [],
        \ }
        \]
  let l:cmd_path = ["level1", "test"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {"cmd": "test"},
        \   [],
        \ ],
        \ l:cmd_obj
        \)
  let l:cmd_path = ["test"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {"cmd": "test", "menu": []},
        \   [],
        \ ],
        \ l:cmd_obj
        \)
endfunction
function! s:tests.find_cmd_obj_returns_cmd_object_walking_path_as_far_as_possible() " {{{1
  " TODO: utilize test data list to shorten code
  let l:menu = [
        \ {
        \   "cmd": "level1",
        \   "menu": [
        \     {
        \       "cmd": "level2",
        \       "menu": [
        \         {
        \           "cmd": "test",
        \         }
        \       ]
        \     },
        \   ]
        \ },
        \]
  let l:cmd_path = ["level1"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {
        \     "cmd": "level1",
        \     "menu": [
        \       {
        \         "cmd": "level2",
        \         "menu": [
        \           {
        \             "cmd": "test"
        \           }
        \         ]
        \       }
        \     ]
        \   },
        \   [],
        \ ],
        \ l:cmd_obj
        \)
  let l:cmd_path = ["level1", "level2"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {
        \     "cmd": "level2",
        \     "menu": [
        \       {
        \         "cmd": "test"
        \       }
        \     ]
        \   },
        \   [],
        \ ],
        \ l:cmd_obj
        \)
  let l:cmd_path = ["level1", "level2", "test"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {
        \     "cmd": "test"
        \   },
        \   [],
        \ ],
        \ l:cmd_obj
        \)
  let l:cmd_path = ["level1", "level2", "level3"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {
        \     "cmd": "level2",
        \     "menu": [
        \       {
        \         "cmd": "test"
        \       }
        \     ]
        \   },
        \   ["level3"],
        \ ],
        \ l:cmd_obj
        \)
  let l:menu = [
        \ {
        \   "cmd": "level1",
        \ }
        \]
  let l:cmd_path = ["level1", "level2", "level3"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal(
        \ [
        \   {
        \     "cmd": "level1"
        \   },
        \   ["level2", "level3"],
        \ ],
        \ l:cmd_obj
        \)
  let l:cmd_path = ["test"]
  let l:cmd_obj = s:find_cmd_obj(l:menu, l:cmd_path)
  call assert_equal([{}, ["test"]], l:cmd_obj)
endfunction
" }}}
function! s:find_cmd_obj(menu, cmd_path)
  let l:cmd_obj = {}
  if empty(a:cmd_path)
    return [l:cmd_obj, []]
  endif
  let l:menu = copy(a:menu)
  let l:cmd_path = a:cmd_path
  while !empty(l:cmd_path)
    let [l:cmd_step; l:cmd_path] = l:cmd_path
    let l:menu_cmd_names = s:cmd_names_in_menu(l:menu)
    let l:cmd_name = s:find_by_prefix_single(l:menu_cmd_names, cmd_step)
    if empty(l:cmd_name)
      return [l:cmd_obj, insert(l:cmd_path, l:cmd_step)]
    endif
    let l:cmd_obj = s:get_cmd_obj_from_menu(l:menu, l:cmd_name)
    let l:menu = get(l:cmd_obj, "menu", [])
  endwhile
  return [l:cmd_obj, l:cmd_path]
endfunction

function! s:tests.invoke_menu_command_executes_menu_action_found_by_command_args() " {{{1
  let l:menus = copy(g:menus)
  let l:invoked = v:false
  function! s:tests._action(args, flag, range, mods) closure
    let l:invoked = v:true
  endfunction
  let g:menus = [
        \ {
        \   "cmd": "Test",
        \   "exec": { a, f, r, m -> s:tests._action(a, f, r, m) },
        \ }
        \]
  let l:command_args = ["Test"]
  call s:invoke_menu_command(
        \ v:false,
        \ [],
        \ l:command_args,
        \ "",
        \)
  call assert_true(l:invoked)
  let g:menus = l:menus
endfunction
function! s:tests.invoke_menu_command_passes_additional_arguments_to_action() " {{{1
  let l:menus = copy(g:menus)
  let l:args = []
  function! s:tests._action(args, flag, range, mods) closure
    let l:args = a:args
  endfunction
  let g:menus = [
        \ {
        \   "cmd": "Test",
        \   "exec": { a, f, r, m -> s:tests._action(a, f, r, m) },
        \ }
        \]
  let l:command_args = ["Test", "arg1", "arg2", "arg3"]
  call s:invoke_menu_command(
        \ v:false,
        \ [],
        \ l:command_args,
        \ "",
        \)
  call assert_equal(["arg1", "arg2", "arg3"], l:args)
  let g:menus = l:menus
endfunction
" }}}
function! s:invoke_menu_command(
      \ flag,
      \ range,
      \ args,
      \ mods,
      \)
  let [l:cmd_obj, l:args_left] = s:find_cmd_obj(g:menus, a:args)
  call s:execute_cmd_obj(l:cmd_obj, l:args_left, a:flag, a:range, a:mods)
endfunction

function! s:tests.execute_cmd_obj_returns_if_there_is_no_exec() " {{{1
  let l:cmd_obj = {
        \ "cmd": "Test",
        \}
  let l:execute_string_command_func_code = execute(
        \ "function! s:execute_string_command"
        \)
  let l:execute_func_command_func_code = execute(
        \ "function! s:execute_func_command"
        \)
  let l:called_any = v:false
  function! s:execute_string_command(m, r, e, f, a) closure
    let l:called_any = v:true
  endfunction
  function! s:execute_func_command(e, a, f, r, m) closure
    let l:called_any = v:true
  endfunction
  silent! call s:execute_cmd_obj(l:cmd_obj, [], v:false, [], "")
  call assert_false(l:called_any)
  execute(l:execute_string_command_func_code)
  execute(l:execute_func_command_func_code)
endfunction
function! s:tests.execute_cmd_obj_executes_string_action() " {{{1
  let l:cmd_obj = {
        \ "cmd": "Test",
        \ "exec": "echo 1",
        \}
  let l:execute_string_command_func_code = execute(
        \ "function! s:execute_string_command"
        \)
  let l:called = v:false
  function! s:execute_string_command(m, r, e, f, a) closure
    let l:called = v:true
  endfunction
  call s:execute_cmd_obj(l:cmd_obj, [], v:false, [], "")
  call assert_true(l:called)
  execute(l:execute_string_command_func_code)
endfunction
function! s:tests.execute_cmd_obj_executes_func_action() " {{{1
  let l:cmd_obj = {
        \ "cmd": "Test",
        \ "exec": { -> v:true },
        \}
  let l:execute_func_command_func_code = execute(
        \ "function! s:execute_func_command"
        \)
  let l:called = v:false
  function! s:execute_func_command(e, a, f, r, m) closure
    let l:called = v:true
  endfunction
  call s:execute_cmd_obj(l:cmd_obj, [], v:false, [], "")
  call assert_true(l:called)
  execute(l:execute_func_command_func_code)
endfunction
function! s:tests.execute_cmd_obj_returns_for_unknown_action_type() " {{{1
  let l:cmd_obj = {
        \ "cmd": "Test",
        \ "exec": 1,
        \}
  let l:called = v:false
  let l:execute_string_command_func_code = execute(
        \ "function! s:execute_string_command"
        \)
  function! s:execute_string_command(m, r, e, f, a) closure
    let l:called = v:true
  endfunction
  let l:execute_func_command_func_code = execute(
        \ "function! s:execute_func_command"
        \)
  function! s:execute_func_command(e, a, f, r, m) closure
    let l:called = v:true
  endfunction
  silent! call s:execute_cmd_obj(l:cmd_obj, [], v:false, [], "")
  call assert_false(l:called)
  execute(l:execute_string_command_func_code)
  execute(l:execute_func_command_func_code)
endfunction
" }}}
function! s:execute_cmd_obj(
      \ cmd_obj,
      \ args,
      \ flag,
      \ range,
      \ mods,
      \)
  try
    let Cmd_exec = a:cmd_obj["exec"]
  catch /E716/
    echohl WarningMsg
    echomsg "Cannot find action to execute"
    echohl None
    return
  endtry
  if type(Cmd_exec) == v:t_string
    call s:execute_string_command(a:mods, a:range, Cmd_exec, a:flag, a:args)
  elseif type(Cmd_exec) == v:t_func
    call s:execute_func_command(Cmd_exec, a:args, a:flag, a:range, a:mods)
  else
    echohl WarningMsg
    echomsg "Unknown type of execution action: ".string(Cmd_exec)
    echohl None
  endif
endfunction

function! s:tests.execute_string_command_executes_all_commands_in_action_string() " {{{1
  let l:action = "echo 1|echo 2"
  redir => l:output
  silent call s:execute_string_command("", [], l:action, v:false, [])
  redir END
  call assert_equal(
        \ "\n1\n2",
        \ l:output,
        \)
endfunction
function! s:tests.execute_string_command_executes_first_command_only_with_mods() " {{{1
  let l:action = "set verbose|set verbose"
  let l:mods = "verbose"
  redir => l:output
  silent call s:execute_string_command(l:mods, [], l:action, v:false, [])
  redir END
  call assert_match(
        \ "^\n  verbose=1\n  verbose=0$",
        \ l:output,
        \)
endfunction
function! s:tests.execute_string_command_executes_first_command_only_with_range() " {{{1
  let l:action = "verbose set verbose|set verbose"
  let l:range = [10]
  redir => l:output
  silent call s:execute_string_command("", l:range, l:action, v:false, [])
  redir END
  call assert_match(
        \ "^\n  verbose=10\n  verbose=0$",
        \ l:output,
        \)
endfunction
function! s:tests.execute_string_command_executes_first_command_with_bang_if_flag_was_passed() " {{{1
  let l:action = "function s:execute_string_command"
  let l:flag = v:true
  redir => l:output
  silent call s:execute_string_command("", [], l:action, l:flag, [])
  redir END
  " with bang, there are no line numbers in output
  call assert_notmatch(
        \ '^\d+',
        \ l:output,
        \)
endfunction
function! s:tests.execute_string_command_passes_args_to_first_command_only() " {{{1
  let l:action = "echo 'start'|echo 'end'"
  let l:args = [1, "arg2"]
  redir => l:output
  silent call s:execute_string_command("", [], l:action, v:false, l:args)
  redir END
  call assert_equal(
        \ "\nstart 1 arg2\nend",
        \ l:output,
        \)
endfunction
" }}}
function! s:execute_string_command(mods, range, exec, flag, args)
  " THIS IS EXPERIMENTAL
  " first command in exec string is a command which should receive a flag (as
  " ! if any)
  if empty(a:exec)
    " nothing to do
    return
  endif
  " only first command receives <bang> and <args>
  " extract first command
  let [l:exec_first_command; l:exec_commands] = split(a:exec, "|")
  " extract command name and original arguments list
  let [l:exec_command; l:exec_command_args] = split(l:exec_first_command)
  " add ! if flag is set, rejoin original arguments
  let l:exec_first_command_flagged =
        \ l:exec_command.
        \ (a:flag ? "!" : "").
        \ " ".
        \ join(l:exec_command_args, " ")
  " add passed arguments to flagged commands with original arguments
  let l:quoted_args = map(a:args, { _, arg -> "'".arg."'" })
  let l:exec_first_command_flag_args = insert(
        \ l:quoted_args,
        \ l:exec_first_command_flagged
        \)
  let l:exec_first_command_flag_args = join(
        \ l:exec_first_command_flag_args,
        \ " "
        \)
  " rejoin additional commands
  let l:exec_commands = insert(
        \ l:exec_commands,
        \ l:exec_first_command_flag_args,
        \)
  let l:exec = join(l:exec_commands, "|")
  " construct whole command to be executed
  let l:command = [
        \ a:mods,
        \ join(a:range, ","),
        \ l:exec,
        \]
  let l:command = join(l:command, " ")
  execute l:command
endfunction

function! s:tests.execute_func_command_passes_arguments_to_exec_function() " {{{1
  let l:call_args = []
  function! s:tests._func_exec(args) closure
    let l:call_args = a:args
  endfunction
  call s:execute_func_command(
        \ { ... -> s:tests._func_exec(a:000) },
        \ ["arg1", 2],
        \ v:true,
        \ [10, 20],
        \ "modifiers",
        \)
  call assert_equal(
        \ [["arg1", 2], v:true, [10, 20], "modifiers"],
        \ l:call_args,
        \)
endfunction
" }}}
function! s:execute_func_command(
      \ exec,
      \ args,
      \ flag,
      \ range,
      \ mods,
      \)
  " function passed as 'exec' will handle all arguments
  call a:exec(a:args, a:flag, a:range, a:mods)
endfunction

function! s:tests.get_partial_command_name_pattern_returns_pattern_that_matches_partially_entered_command_name() " {{{1
  let l:command_name = "Test"
  let l:entered_partial_command_with_range_and_bang = "2,3Tes!"
  let l:expected_command_name = "Tes"
  let l:pattern = s:get_partial_command_name_pattern(l:command_name)
  call assert_equal(
        \ l:expected_command_name,
        \ matchstr(l:entered_partial_command_with_range_and_bang, l:pattern),
        \)
  let l:entered_partial_command = "Te"
  call assert_equal(
        \ l:expected_command_name,
        \ matchstr(l:entered_partial_command_with_range_and_bang, l:pattern),
        \)
endfunction
" }}}
function! s:get_partial_command_name_pattern(word)
  let l:first_char = a:word[0]
  let l:rest = a:word[1:]
  return '\v('.l:first_char.'%['.l:rest.'])[[:alnum:]]@!'
endfunction

function! s:tests.get_command_name_from_cmdline_returns_potentially_partially_entered_command_name_from_cmdline() " {{{1
  let l:menus = copy(g:menus)
  let g:menus = [
        \ {
        \   "cmd": "Test",
        \ }
        \]
  let l:test_data = [
        \ {
        \   "cmdline": "Tes arg1",
        \   "expected": "Tes",
        \ },
        \ {
        \   "cmdline": "Test!",
        \   "expected": "Test",
        \ },
        \ {
        \   "cmdline": "2,3Te 1",
        \   "expected": "Te",
        \ },
        \ {
        \   "cmdline": "verbose silent botright Test",
        \   "expected": "Test",
        \ },
        \]
  for data in l:test_data
    let l:command_found = s:get_command_name_from_cmdline(data["cmdline"])
    call assert_equal(
          \ data["expected"],
          \ l:command_found,
          \)
  endfor
  let g:menus = l:menus
endfunction
function! s:tests.get_command_name_from_cmdline_dont_match_externally_defined_commands() " {{{1
  let l:cmdline = "Explore"
  let l:expected = ""
  let l:command_found = s:get_command_name_from_cmdline(l:cmdline)
  call assert_equal(
        \ l:expected,
        \ l:command_found,
        \)
endfunction
" }}}
function! s:get_command_name_from_cmdline(cmdline)
  for command_name in s:cmd_names_in_menu(g:menus)
    let l:partial_command_name_pattern = s:get_partial_command_name_pattern(command_name)
    let l:partial_command_name = matchstr(
          \ a:cmdline,
          \ '\v\C(^|[^\I])\zs'.l:partial_command_name_pattern.'\ze'
          \)
    if !empty(l:partial_command_name)
      return l:partial_command_name
    endif
  endfor
  return ""
endfunction

function! s:tests.get_command_args_returns_arguments_string_following_entered_command() " {{{1
  let l:test_data = [
        \ {
        \   "cmdline": "Test",
        \   "cmdname": "Test",
        \   "expected": "",
        \ },
        \ {
        \   "cmdline": "2Test! arg1 2 3 ",
        \   "cmdname": "Test",
        \   "expected": "arg1 2 3",
        \ },
        \]
  for data in l:test_data
    let l:args_found = s:get_command_args(data["cmdname"], data["cmdline"])
    call assert_equal(
          \ data["expected"],
          \ l:args_found,
          \)
  endfor
endfunction
" }}}
function! s:get_command_args(command_name, cmdline)
  let l:args = matchstr(
        \ a:cmdline,
        \ '\v\C(^|[^\I])'.a:command_name.'!?\s+\zs(.{-})\ze\s*$',
        \)
  return l:args
endfunction

function! s:tests.complete_menu_cmd_provides_completions_based_on_arguments_entered_so_far() " {{{1
  let l:menus = copy(g:menus)
  let g:menus = [
        \ {
        \   "cmd": "TestEmpty"
        \ },
        \ {
        \   "cmd": "Test",
        \   "menu": [
        \     {
        \       "cmd": "first",
        \       "menu": [
        \         {
        \           "cmd": "nested"
        \         }
        \       ]
        \     },
        \     {
        \       "cmd": "second",
        \     },
        \   ],
        \ },
        \]
  let l:test_data = [
        \ {
        \   "entering": "",
        \   "cmdline": "TestE ",
        \   "expected": join([], "\n"),
        \ },
        \ {
        \   "entering": "fi",
        \   "cmdline": "Test fi",
        \   "expected": join(["first", "second"], "\n"),
        \ },
        \ {
        \   "entering": "sth",
        \   "cmdline": "Test fi sth",
        \   "expected": join(["nested"], "\n"),
        \ },
        \ {
        \   "entering": "",
        \   "cmdline": "Test ",
        \   "expected": join(["first", "second"], "\n"),
        \ },
        \]
  for data in l:test_data
    let l:completions = s:complete_menu_cmd(data["entering"], data["cmdline"], 0)
    call assert_equal(
          \ data["expected"],
          \ l:completions,
          \)
  endfor
  let g:menus = l:menus
endfunction
function! s:tests.complete_menu_cmd_uses_complete_function_of_found_cmd_object_for_futher_completions() " {{{1
  let l:menus = copy(g:menus)
  function! s:tests._should_not_be_called()
    call assert_true(v:false, "I should not have been called")
    return []
  endfunction
  let g:menus = [
        \ {
        \   "cmd": "TestEmpty",
        \   "menu": [
        \   ],
        \   "complete": { a, as -> s:tests._should_not_be_called() },
        \ },
        \ {
        \   "cmd": "Test",
        \   "menu": [
        \     {
        \       "cmd": "custom_completion",
        \       "complete": { a, as -> ["compl1", "compl2"] },
        \     },
        \   ],
        \   "complete": { a, as -> s:tests._should_not_be_called() },
        \ },
        \]
  let test_data = [
        \ {
        \   "entering": "",
        \   "cmdline": "TestEmpty ",
        \   "expected": ""
        \ },
        \ {
        \   "entering": "any",
        \   "cmdline": "Test cus any",
        \   "expected": join(["compl1", "compl2"], "\n")
        \ },
        \]
  for data in test_data
    let l:completions = s:complete_menu_cmd(data["entering"], data["cmdline"], 0)
    call assert_equal(
          \ data["expected"],
          \ l:completions,
          \)
  endfor
  let g:menus = l:menus
endfunction
" }}}
function! s:complete_menu_cmd(
      \ cmd_being_entered,
      \ cmdline,
      \ cursorpos,
      \)
  let l:entered_cmd_name = s:get_command_name_from_cmdline(a:cmdline)
  let l:full_cmd_name = s:find_by_prefix_single(
        \ s:cmd_names_in_menu(g:menus),
        \ l:entered_cmd_name,
        \)
  function! s:menu_path() closure
    let l:cmd_path_and_args = s:get_command_args(l:entered_cmd_name, a:cmdline)
    let l:cmd_path_and_args = split(l:cmd_path_and_args)
    let l:cmd_path_and_args = insert(l:cmd_path_and_args, l:full_cmd_name)
    if !empty(a:cmd_being_entered)
      let l:cmd_path_and_args = l:cmd_path_and_args[:-2]
    endif
    return l:cmd_path_and_args
  endfunction
  let [l:cmd_obj, l:cmd_args] = s:find_cmd_obj(
        \ g:menus,
        \ s:menu_path(),
        \)
  " if l:cmd_obj has 'complete' key, but not 'menu' key (even empty),
  " then use it to provide completions
  if has_key(l:cmd_obj, "complete") && !has_key(l:cmd_obj, "menu")
    echomsg string(l:cmd_obj)
    echomsg string(l:cmd_args)
    let l:cmds_in_menu = l:cmd_obj["complete"](a:cmd_being_entered, l:cmd_args)
    echomsg string(l:cmds_in_menu)
  else
    let l:cmds_in_menu = s:cmd_names_in_menu(get(l:cmd_obj, "menu", []))
  endif
  return join(l:cmds_in_menu, "\n")
endfunction
