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
function! s:tests._is_full_command(name)
  let l:result = exists(":".a:name)
  return l:result == 2
endfunction

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

function! s:tests.find_by_prefix_single_returns_name_matching_prefix_unambiguously()
  let l:names = [
        \ "name_abc",
        \ "name_def",
        \]
  let l:name_prefix = "name_d"
  let l:name_found = s:find_by_prefix_single(l:names, l:name_prefix)
  call assert_equal("name_def", l:name_found)
endfunction
function! s:tests.find_by_prefix_single_returns_empty_string_when_no_or_multiple_matches_found()
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
function! s:tests.find_by_prefix_single_returns_exact_match_when_multiple_matches_found()
  let l:names = [
        \ "name_abc",
        \ "name_def",
        \ "name",
        \]
  let l:name_prefix = "name"
  let l:name_found = s:find_by_prefix_single(l:names, l:name_prefix)
  call assert_equal("name", l:name_found)
endfunction
function! s:find_by_prefix_single(names, name)
  let l:names_matching_prefix = filter(
        \ copy(a:names),
        \ { _, name -> name =~# '\v^'.a:name },
        \)
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

function! s:tests.update_menu_commands_creates_new_commands_for_all_menus()
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
function! menu_builder#update_menu_commands()
  for menu_name in s:cmd_names_in_menu(g:menus)
    call s:update_menu_command(menu_name)
  endfor
endfunction

function! s:tests.update_menu_command_given_cmd_name()
  let l:cmd_name = "TestCommand"
  call s:update_menu_command(l:cmd_name)
  call assert_true(s:tests._is_full_command(l:cmd_name))
  execute "delcommand ".l:cmd_name
endfunction
function! s:tests.update_menu_command_fails_on_invalid_name()
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

function! s:tests.find_cmd_obj_returns_cmd_object_in_flat_menu_structure()
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
function! s:tests.find_cmd_obj_returns_empty_dict_if_no_cmd_obj_found()
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
function! s:tests.find_cmd_obj_returns_empty_dict_if_no_path_given()
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
function! s:tests.find_cmd_obj_returns_cmd_object_matching_prefix()
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
function! s:tests.find_cmd_obj_returns_cmd_object_in_nested_menu_structure()
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
function! s:tests.find_cmd_obj_returns_cmd_object_walking_path_as_far_as_possible()
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

function! s:tests.invoke_menu_command_executes_menu_action_found_by_command_args()
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
function! s:tests.invoke_menu_command_passes_additional_arguments_to_action()
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
function! s:invoke_menu_command(
      \ flag,
      \ range,
      \ args,
      \ mods,
      \)
  let [l:cmd_obj, l:args_left] = s:find_cmd_obj(g:menus, a:args)
  call s:execute_cmd_obj(l:cmd_obj, l:args_left, a:flag, a:range, a:mods)
endfunction

function! s:tests.execute_cmd_obj_returns_if_there_is_no_exec()
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
  call s:execute_cmd_obj(l:cmd_obj, [], v:false, [], "")
  call assert_false(l:called_any)
  execute(l:execute_string_command_func_code)
  execute(l:execute_func_command_func_code)
endfunction
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
    echomsg "Unknown type of execution action: ".string(Cmd_exec).
          \   ": ".type(Cmd_exec)
    echohl None
  endif
endfunction

function! s:execute_string_command(mods, range, exec, flag, args)
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

function! s:get_partial_pattern(word)
  let l:first_char = a:word[0]
  let l:rest = a:word[1:]
  let l:pattern = "(".l:first_char."("
  let l:partial_matches = []
  while len(l:rest)
    let l:partial_matches = add(
          \ l:partial_matches,
          \ l:rest
          \)
    let l:rest = l:rest[:-2]
  endwhile
  let l:pattern .= join(l:partial_matches, "|")
  let l:pattern .= "?))"
  return l:pattern
endfunction

function! s:get_whole_command_name(partial_command_name)
  let l:command_candidates = filter(
        \ keys(g:menus),
        \ { _, c -> c =~# '\v^'.a:partial_command_name }
        \)
  if empty(l:command_candidates)
    return ""
  endif
  if len(l:command_candidates) == 1
    return l:command_candidates[0]
  endif
  " there should be exact match and other commands that start with
  " partial_command_name
  let l:command_name_index = index(
        \ l:command_candidates,
        \ a:partial_command_name
        \)
  if l:command_name_index < 0
    return ""
  endif
  return l:command_candidates[l:command_name_index]
endfunction

function! s:get_command_name(cmdline)
  for command_name in keys(g:menus)
    let l:partial_command_name_pattern = s:get_partial_pattern(command_name)
    let l:partial_command_name = matchstr(
          \ a:cmdline,
          \ '\v\C(^|[^\I])\zs'.l:partial_command_name_pattern.'\ze!?\s+'
          \)
    if !empty(l:partial_command_name)
      return l:partial_command_name
    endif
  endfor
  return ""
endfunction

function! s:get_command_args(command_name, cmdline)
  let l:args = matchstr(
        \ a:cmdline,
        \ '\v\C(^|[^\I])'.a:command_name.'!?\s+\zs(.*)\ze',
        \)
  return l:args
endfunction

function! s:complete_menu_cmd(
      \ cmd_being_entered,
      \ cmdline,
      \ cursorpos,
      \)
  " possible items in current menu node
  " current menu mode determined by menu path entered so far, not taking
  " item_being_entered into account
  " menu path entered so far counts from first item after whitespace following
  " command name until last whitespace preceding item_being_entered (which may
  " be empty)
  let l:entered_cmd_name = s:get_command_name(a:cmdline)
  let l:cmd_name = s:get_whole_command_name(l:entered_cmd_name)
  let l:cmd_path_and_args = s:get_command_args(l:entered_cmd_name, a:cmdline)
  let l:cmd_path_and_args = split(l:cmd_path_and_args)
  if !empty(a:cmd_being_entered)
    let l:cmd_path_and_args = l:cmd_path_and_args[:-2]
  endif
  let [l:cmd_obj, l:cmd_args] = menu_builder#find_cmd_obj(
        \ l:cmd_name,
        \ l:cmd_path_and_args,
        \)
  let l:cmd_objs_in_menu = s:cmd_names_from_menu_starting_with(
        \ get(l:cmd_obj, "menu", []),
        \ '.*',
        \)
  let l:cmds_in_menu = map(
        \ l:cmd_objs_in_menu,
        \ { _, co -> co["cmd"] },
        \)
  return join(l:cmds_in_menu, "\n")
endfunction

" vim:foldmethod=marker:fmr=function!\ s\:tests.,endfunction
