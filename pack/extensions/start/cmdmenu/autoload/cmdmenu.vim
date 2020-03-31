let s:command_name_pattern = '\v^(\U)*\zs\u\a+\ze'
function! s:cmdline_command_name(cmdline)
  return matchstr(a:cmdline, s:command_name_pattern)
endfunction

let s:command_args_pattern = '\v^(\U)*\u\a+!?\s+\zs.*\ze$'
function! s:cmdline_command_args(cmdline)
  let l:args_str = matchstr(a:cmdline, s:command_args_pattern)
  return split(l:args_str, '\v\ +')
endfunction

function! s:get_cmdline_state()
  return s:cmdline_state
endfunction

function! s:reset_cmdline_state()
  let s:cmdline_state = {
        \ "cmd": "",
        \ "args": [],
        \ "pos": 0,
        \}
endfunction
call s:reset_cmdline_state()

function! s:cmdline_parse(cmdline, cmdpos)
  let s:cmdline_state["cmd"] = s:cmdline_command_name(a:cmdline)
  let s:cmdline_state["args"] = s:cmdline_command_args(a:cmdline)
  let s:cmdline_state["pos"] = a:cmdpos
endfunction

function! s:is_cmdmenu_command(cmdline_state)
  let l:cmdline_command = a:cmdline_state["cmd"]
  let l:full_command_from_menu = util#single_matching_prefix(l:cmdline_command)
        \(s:get_all_cmds_from_menu(g:cmdmenu))
  return !empty(l:full_command_from_menu)
endfunction

function! s:update_cmdmenu(cmdline, cmdpos)
  call s:cmdline_parse(a:cmdline, a:cmdpos)
  let l:cmdline_state = s:get_cmdline_state()
  if !s:is_cmdmenu_command(l:cmdline_state)
    return
  endif
  call s:display_menu(l:cmdline_state)
endfunction

function! s:display_menu(cmdline_state)
  " open window with list of possible commands given entered path
  let l:cmds = s:get_cmds_from_cmdline_state(a:cmdline_state)
  echomsg "Cmds: ".string(l:cmds)
endfunction

function! s:get_cmds_from_cmdline_state(cmdline_state)
  let l:cmd_path = extend(
        \ [copy(a:cmdline_state["cmd"])],
        \ a:cmdline_state["args"]
        \)
  let [l:cmd_obj, l:cmd_args] = s:get_cmd_obj_by_path(g:cmdmenu, l:cmd_path)
  let l:cmds = s:get_all_cmds_from_menu(get(l:cmd_obj, "menu", []))
  return l:cmds
endfunction

augroup cmdmenu_monitor_cmdline
  autocmd!
  autocmd CmdlineEnter : call <sid>reset_cmdline_state()
  autocmd CmdlineChanged : call <sid>update_cmdmenu(getcmdline(), getcmdpos())
  autocmd CmdlineLeave : call <sid>reset_cmdline_state()
augroup end

if !exists("g:cmdmenu")
  let g:cmdmenu = []
endif

function! s:get_cmd_obj_from_menu(menu, cmd)
  let l:cmd_obj = func#filter(
        \ { _, c -> c["cmd"] ==# a:cmd },
        \)
        \(a:menu)
  return !empty(l:cmd_obj) ? l:cmd_obj[0] : {}
endfunction

function! s:get_all_cmds_from_menu(menu)
  return func#map({ _, c -> c["cmd"] })(a:menu)
endfunction

function! s:get_cmd_obj_by_path(menu, path)
  let l:cmd_obj = {}
  if empty(a:path)
    return [l:cmd_obj, []]
  endif
  let l:menu = copy(a:menu)
  let l:path = a:path
  while !empty(l:path)
    let [l:next_cmd; l:path] = l:path
    let l:menu_cmds = s:get_all_cmds_from_menu(l:menu)
    let l:cmd = util#single_matching_prefix(l:next_cmd)(l:menu_cmds)
    if empty(l:cmd)
      return [l:cmd_obj, insert(l:path, l:next_cmd)]
    endif
    let l:cmd_obj = s:get_cmd_obj_from_menu(l:menu, l:cmd)
    let l:menu = get(l:cmd_obj, "menu", [])
  endwhile
  return [l:cmd_obj, l:path]
endfunction

function! cmdmenu#update_commands()
  for cmd in s:get_all_cmds_from_menu(g:cmdmenu)
    call s:update_command(cmd)
  endfor
endfunction

function! s:update_command(cmd)
  let l:cmd_rhs_func_args = [
        \ "'".a:cmd."'",
        \ "<bang>v:false",
        \ "split(<q-args>)",
        \ "<q-mods>",
        \]
  let l:cmd_rhs_func_args = join(l:cmd_rhs_func_args, ", ")
  let l:execute_cmd_func = "<line1>,<line2>call s:execute_cmd(".l:cmd_rhs_func_args.")"
  let l:cmd_def = [
        \ "command!",
        \ "-nargs=*",
        \ "-range",
        \ "-bang",
        \ "-complete=custom,s:complete_cmd",
        \ a:cmd,
        \ l:execute_cmd_func,
        \]
  let l:cmd_def = join(l:cmd_def, " ")
  execute l:cmd_def
endfunction

function! s:execute_cmd(cmd, flag, cmd_args, mods) range
  let l:cmd_path = extend([copy(a:cmd)], a:cmd_args)
  let [l:cmd_obj, l:args] = s:get_cmd_obj_by_path(g:cmdmenu, l:cmd_path)
  if !has_key(l:cmd_obj, "action")
    echohl WarningMsg
    echomsg "No action for this command"
    echohl None
    return
  endif
  execute a:firstline.",".a:lastline.
        \   "call l:cmd_obj['action'](l:args, a:flag, a:mods)"
endfunction

function! s:complete_cmd(arg_prefix, cmdline, curpos)
  let l:cmdline_state = s:get_cmdline_state()
  let l:cmds = s:get_cmds_from_cmdline_state(l:cmdline_state)
  return join(l:cmds, "\n")
endfunction
