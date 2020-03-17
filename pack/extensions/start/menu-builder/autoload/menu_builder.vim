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
let g:menus["Test"] = add(
      \ g:menus["Test"],
      \ s:test_cmd_1,
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

function! menu_builder#find_cmd_obj(menu_name, command_args)
  " TODO implement searching for cmd object
  return [s:test_cmd_2, a:command_args[1:]]
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
