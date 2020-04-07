if !exists("g:cmdmenu")
  let g:cmdmenu = []
endif

function! s:menu_cmds(menu)
  const l:key = "cmd"
  return func#compose(
        \ list#filter({_, co -> has_key(co, l:key)}),
        \ list#map({_,co -> co[l:key]})
        \)
        \(a:menu)
endfunction

function! cmdmenu#update_commands()
  for cmd in s:menu_cmds(g:cmdmenu)
    call s:update_command(cmd)
  endfor
endfunction

function! s:update_command(cmd)
  let l:cmd_rhs_func_args = [
        \ "<bang>0",
        \ "split(<q-args>)",
        \ "<q-mods>",
        \]
  let l:cmd_rhs_func_args = join(l:cmd_rhs_func_args, ", ")
  let l:cmd_rhs_func_call = "<line1>,<line2>call s:execute_cmd(".l:cmd_rhs_func_args.")"
  let l:cmd_def = [
        \ "command!",
        \ "-nargs=*",
        \ "-range",
        \ "-bang",
        \ "-complete=custom,s:complete_cmd",
        \ a:cmd,
        \ l:cmd_rhs_func_call,
        \]
  let l:cmd_def = join(l:cmd_def, " ")
  execute l:cmd_def
endfunction

function! s:execute_cmd(flag, args, mods) range abort
  let l:cmdline_state = s:state
  call s:reset_state()
  let l:cmd_obj = l:cmdline_state["cmd_obj"]
  let l:cmd_args = l:cmdline_state["cmd_args"]
  if !has_key(l:cmd_obj, "action")
    echohl WarningMsg
    echomsg "No action for this command"
    echohl None
    return
  endif
  execute a:firstline.",".a:lastline."call l:cmd_obj['action'](l:cmd_args, a:flag, a:mods)"
endfunction

function! s:complete_cmd(arglead, cmdline, curpos)
  let l:cmd_obj = s:state["cmd_obj"]
  let l:cmd_args = s:state["cmd_args"]
  let s:should_open_cmdmenu_win = v:true
  " invoke custom completion function only if there is no possibility to go
  " deeper into submenus, otherwise there is unambiguity in completions
  " provider
  if !has_key(l:cmd_obj, "menu") && has_key(l:cmd_obj, "complete")
    let l:completion_candidates = l:cmd_obj["complete"](a:arglead, l:cmd_args)
  elseif empty(l:cmd_args)
    let l:submenu = get(l:cmd_obj, "menu", [])
    let l:completion_candidates = s:menu_cmds(l:submenu)
  else
    let l:completion_candidates = []
  endif
  return join(l:completion_candidates, "\n")
endfunction

function! s:parse_cmdline(cmdline)
  let l:parsed = matchlist(a:cmdline, '\v^\U*(\u\a*)!?\s*(.*)$')[1:2]
  if len(l:parsed) != 2
    return ["", ""]
  endif
  return l:parsed
endfunction

function! s:_prefix_single_match(prefix, cmds)
  if empty(a:prefix)
    return ""
  endif
  const l:all_cmds_matching_prefix = func#compose(
        \ list#filter({_, c -> c =~# '\v^'.a:prefix}),
        \)
        \(a:cmds)
  if !empty(l:all_cmds_matching_prefix)
    if len(l:all_cmds_matching_prefix) == 1
      return l:all_cmds_matching_prefix[0]
    endif
    const l:exact_match = list#filter(
          \ {_, m -> m ==# a:prefix},
          \)
          \(l:all_cmds_matching_prefix)
    if !empty(l:exact_match)
      return l:exact_match[0]
    endif
  endif
  return ""
endfunction
function! s:prefix_single_match(prefix)
  return funcref("s:_prefix_single_match", [a:prefix])
endfunction

function! s:menu_cmd_obj(menu, cmd)
  const l:key = "cmd"
  const l:cmd_objs = func#compose(
        \ list#filter({_, co -> has_key(co, l:key)}),
        \ list#filter({_, co -> co[l:key] ==# a:cmd}),
        \)
        \(a:menu)
  return get(l:cmd_objs, 0, {})
endfunction

function! s:cmd_obj_by_path(menu, path)
  if empty(a:path)
    return [{}, []]
  endif
  let l:menu = copy(a:menu)
  let l:path = a:path
  let l:cmd_obj = {}
  while !empty(l:path)
    let [l:next_cmd; l:next_path] = l:path
    let l:cmd = s:prefix_single_match(l:next_cmd)(s:menu_cmds(l:menu))
    if empty(l:cmd)
      break
    endif
    let l:cmd_obj = s:menu_cmd_obj(l:menu, l:cmd)
    let l:menu = get(l:cmd_obj, "menu", [])
    let l:path = l:next_path
  endwhile
  return [l:cmd_obj, l:path]
endfunction

function! s:reset_state()
  let s:state = {
        \ "cmd_obj": {},
        \ "cmd_args": [],
        \}
endfunction

function! s:single_cmdmenu_command(command)
  let l:all_commands = keys(nvim_get_commands({}))
  let l:command = s:prefix_single_match(a:command)(l:all_commands)
  if list#contains(s:menu_cmds(get(g:, "cmdmenu", [])), l:command)
    return l:command
  else
    return ""
  endif
endfunction

function! s:set_state(cmdline, cmdcurpos, execute)
  let [l:command, l:args] = s:parse_cmdline(a:cmdline)
  let l:command = s:single_cmdmenu_command(l:command)
  if empty(l:command)
    return
  endif
  let l:cmd_path = split(l:args)
  if !a:execute && a:cmdline =~# '\v\S$'
    let l:cmd_path = l:cmd_path[:-2]
  endif
  let l:cmd_path = extend([l:command], l:cmd_path)
  let [l:cmd_obj, l:cmd_args] = s:cmd_obj_by_path(get(g:, "cmdmenu", []), l:cmd_path)
  let s:state["cmd_obj"] = l:cmd_obj
  let s:state["cmd_args"] = l:cmd_args
endfunction

function! s:on_enter()
  call s:reset_state()
endfunction

function! s:store_user_settings()
  "echomsg printf("storing settings: %s", &wildmenu)
  let s:user_wildmenu = &wildmenu
  set nowildmenu
endfunction

function! s:open_cmdmenu_win()
  echomsg printf("open new cmdmenu window")
endfunction

function! s:open_cmdmenu_window()
  echomsg get(s:, "should_open_cmdmenu_win", v:false)
  if get(s:, "should_open_cmdmenu_win", v:false)
    call s:store_user_settings()
    call s:open_cmdmenu_win()
  endif
endfunction

function! s:restore_user_settings()
  if exists("s:user_wildmenu")
    "echomsg printf("restoring settings: %s", s:user_wildmenu)
    let &wildmenu = s:user_wildmenu
    unlet s:user_wildmenu
  endif
endfunction

function! s:close_cmdmenu_win()
  "echomsg printf("close cmdmenu window, if any")
endfunction

function! s:close_cmdmenu_window()
  call s:restore_user_settings()
  call s:close_cmdmenu_win()
endfunction

function! s:on_change(cmdline, cmdcurpos)
  echomsg printf("on change, cmdline: %s", a:cmdline)
  call s:close_cmdmenu_window()
  call s:set_state(a:cmdline, a:cmdcurpos, v:false)
  call s:open_cmdmenu_window()
endfunction

function! s:on_leave(cmdline, cmdcurpos)
  echomsg printf("on leave, cmdline: %s", a:cmdline)
  let s:should_open_cmdmenu_win = v:false
  call s:close_cmdmenu_window()
  call s:set_state(a:cmdline, a:cmdcurpos, v:true)
  if !v:event["abort"] && !empty(s:state["cmd_obj"])
    echomsg printf("to execute: %s with args: %s", s:state["cmd_obj"], s:state["cmd_args"])
  endif
endfunction

augroup cmdmenu_monitoring
  autocmd!
  autocmd CmdlineEnter : call <sid>on_enter()
  autocmd CmdlineChanged : call <sid>on_change(getcmdline(), getcmdpos())
  autocmd CmdlineLeave : call <sid>on_leave(getcmdline(), getcmdpos())
augroup end
