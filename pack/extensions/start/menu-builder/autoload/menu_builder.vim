if !exists("g:menus")
  let g:menus = {}
endif

" =============================================================================
" Function has to accept 4 arguments:
" 1. args - List(string), list of additional command arguments
" 2. flag - boolean, indicates if menu was invoked with <bang>
" 3. range - List(int), list containing 0, 1 or 2 integers indicating range
"           on which menu was invoked
" 4. mods - string, command modifiers string (:help <mods>)
function! s:command_1_func(args, flag, range, mods)
  echomsg "Command 1 execution:"
  echomsg "args: ".string(a:args)
  echomsg "flag: ".a:flag
  echomsg "range: ".string(a:range)
  echomsg "mods: ".a:mods
endfunction

let g:menus["Test"] = []
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
      \   s:test_cmd_1,
      \   s:test_cmd_2,
      \ ]
      \)

" =============================================================================
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

function! s:find_cmd_name_in_menu(current_cmd_obj, cmd_name)
  return filter(
        \ copy(get(a:current_cmd_obj, "menu", [])),
        \ { _, cmd_obj -> get(cmd_obj, "cmd", v:false) ==# a:cmd_name },
        \)
endfunction

function! menu_builder#find_cmd_obj(menu_name, command_args)
  " TODO implement searching for cmd object
  let l:menu = get(g:menus, a:menu_name, [])
  if empty(a:command_args) || empty(l:menu)
    return [{}, []]
  endif
  function! s:walk_menus(current_cmd_obj, cmd_path)
    if empty(a:cmd_path)
      return [a:current_cmd_obj, []]
    endif
    if !has_key(a:current_cmd_obj, "menu")
      return [a:current_cmd_obj, a:cmd_path]
    endif
    let [l:next_cmd_name; l:next_cmd_path] = a:cmd_path
    let l:next_cmd_obj = s:find_cmd_name_in_menu(
          \ a:current_cmd_obj,
          \ l:next_cmd_name,
          \)
    if len(l:next_cmd_obj) != 1
      if len(l:next_cmd_obj) > 1
        echohl WarningMsg
        echomsg "Cannot find single cmd object with '".l:next_cmd_name."' name"
        echohl None
      endif
      return [a:current_cmd_obj, a:cmd_path]
    endif
    return s:walk_menus(l:next_cmd_obj[0], l:next_cmd_path)
  endfunction
  return s:walk_menus({"cmd": a:menu_name, "menu": l:menu}, a:command_args)
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
    let Cmd_exec = get(a:cmd_obj, "exec")
  catch /E716/
    echohl WarningMsg
    echomsg "Execution action ('exec' key) not found in ".string(a:cmd_obj)
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
  let l:cmds_in_menu = []
  return join(l:cmds_in_menu, "\n")
endfunction

" vim:foldmethod=indent
