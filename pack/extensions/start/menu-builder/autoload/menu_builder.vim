" Menu builder plugin for building custom menu trees as Vim commands with
" arguments.
"
" Data type:
" cmd_object - Dictionary with following keys:
"   - cmd - (String) (Sub)command name. Mandatory. Uniquely identifies
"           cmd_object inside menu. Cannot contain spaces or double-quotes. To
"           uniquely identify cmd object in menu, shortest prefix is
"           sufficient. If prefix is also a full cmd value, it identifies this
"           cmd object.
"           Example:
"
"               [{"cmd": "short"}, {"cmd": "shortest"}]
"
"               "short": identifies first cmd object (prefix matches also
"               second cmd object, but first one is a full match)
"               "shorte": identifies second cmd object (the only match for
"               prefix)
"               "shor": does not uniquely identify any object (prefix matches
"               both objects)
"
"   - menu - (List[cmd_object]) Defines subcommands for given cmd object.
"            Optional, mandatory if there is no exec attribute in cmd object.
"            Cmd objects in menu are available only when current cmd object is
"            selected (by uniquely identifying path). Completion candidates
"            for Vim command (top-level menu) are selected from cmd attribute
"            values of cmd objects in menu attribute. If there is no menu
"            attribute in cmd object, there are no cmd completion candidates
"            (leaf cmd object).
"
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
  let g:menus = {}
endif

" =============================================================================
function! s:command_1_func(args, flag, range, mods)
  echomsg "Command 1 execution:"
  echomsg "args: ".string(a:args)
  echomsg "flag: ".a:flag
  echomsg "range: ".string(a:range)
  echomsg "mods: ".a:mods
endfunction

let g:menus["Test"] = []
let g:menus["Test1"] = []
let g:menus["Test2"] = []
let s:test_cmd = {
      \ "cmd": "command",
      \ "menu": [
      \   {
      \     "cmd": "second",
      \     "exec": "echo 'command'",
      \   },
      \   {
      \     "cmd": "sec",
      \     "exec": "echo 'sec'",
      \   }
      \ ]
      \}
let s:test_cmd_1 = {
      \ "cmd": "command_1",
      \ "exec": function("s:command_1_func"),
      \}
let s:test_cmd_2 = {
      \ "cmd": "command_2",
      \ "exec": "echo 'test'|echo 'after'",
      \}
let g:menus["Test"] = extend(
      \ g:menus["Test"],
      \ [
      \   s:test_cmd,
      \ ]
      \)
let g:menus["Test1"] = extend(
      \ g:menus["Test1"],
      \ [
      \   s:test_cmd_1,
      \ ]
      \)
let g:menus["Test2"] = extend(
      \ g:menus["Test2"],
      \ [
      \   s:test_cmd_2,
      \ ]
      \)

" =============================================================================
function! s:cmd_names_from_menu_starting_with(
      \ menu,
      \ cmd_name_prefix_pattern,
      \)
  return filter(
        \ copy(a:menu),
        \ { _, cmd_obj -> cmd_obj["cmd"] =~# '\v^'.a:cmd_name_prefix_pattern },
        \)
endfunction

function! menu_builder#update_menu_commands()
  for menu_name in keys(g:menus)
    call menu_builder#update_menu_command(menu_name)
  endfor
endfunction

function! menu_builder#update_menu_command(menu_name)
  let l:command_def = [
        \ "command!",
        \ "-nargs=+",
        \ "-complete=custom,s:complete_menu_cmd",
        \ "-range",
        \ "-bang",
        \ "-bar",
        \ a:menu_name,
        \ "call s:invoke_menu_command(",
        \ '"'.a:menu_name.'",',
        \ "<bang>v:false,",
        \ "<range>?[<line1>,<line2>][0:<range>-1]:[],",
        \ "split(<q-args>),",
        \ "<q-mods>,",
        \ ")",
        \]
  let l:command_def = join(l:command_def, " ")
  execute l:command_def
endfunction

function! menu_builder#find_cmd_obj(menu_name, command_args)
  let l:menu = get(g:menus, a:menu_name, [])
  let l:menu_obj = {"cmd": a:menu_name, "menu": l:menu}
  if empty(a:command_args) || empty(l:menu)
    return [l:menu_obj, []]
  endif
  function! s:walk_menus(current_cmd_obj, cmd_path)
    if empty(a:cmd_path)
      return [a:current_cmd_obj, []]
    endif
    if !has_key(a:current_cmd_obj, "menu")
      return [a:current_cmd_obj, a:cmd_path]
    endif
    let [l:next_cmd_name; l:next_cmd_path] = a:cmd_path
    let l:next_cmd_obj_candidates = s:cmd_names_from_menu_starting_with(
          \ a:current_cmd_obj["menu"],
          \ l:next_cmd_name,
          \)
    " try to find exact match where multiple cmds start with next_cmd_name
    if len(l:next_cmd_obj_candidates) > 1
      let l:next_cmd_obj_candidates = filter(
            \ l:next_cmd_obj_candidates,
            \ { _, co -> co["cmd"] ==# l:next_cmd_name },
            \)
    endif
    if len(l:next_cmd_obj_candidates) != 1
      if len(l:next_cmd_obj_candidates) > 1
        echohl WarningMsg
        echomsg "Cannot find single cmd object with '".l:next_cmd_name."' name"
        echohl None
      endif
      return [a:current_cmd_obj, a:cmd_path]
    endif
    return s:walk_menus(l:next_cmd_obj_candidates[0], l:next_cmd_path)
  endfunction
  return s:walk_menus(l:menu_obj, a:command_args)
endfunction

function! s:invoke_menu_command(
      \ menu_name,
      \ flag,
      \ range,
      \ args,
      \ mods,
      \)
  let [l:cmd_obj, l:cmd_args] = menu_builder#find_cmd_obj(a:menu_name, a:args)
  call s:execute_cmd_obj(l:cmd_obj, l:cmd_args, a:flag, a:range, a:mods)
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

" vim:foldmethod=indent
