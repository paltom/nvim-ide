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

function! s:execute_cmd(command, flag, args, mods) range abort
  let l:cmdmenu = get(g:, "cmdmenu", [])
  let l:cmd_path = extend([a:command], a:args)
  let [l:cmd_obj, l:cmd_args] = s:cmd_obj_by_path(l:cmdmenu, l:cmd_path)
  if !has_key(l:cmd_obj, "action")
    echohl WarningMsg
    echomsg "No action for this command"
    echohl None
    return
  endif
  execute a:firstline.",".a:lastline."call l:cmd_obj['action'](l:cmd_args, a:flag, a:mods)"
endfunction

function! s:parse_cmdline(cmdline)
  let l:parsed = matchlist(a:cmdline, '\v^\U*(\u\a*)!?\s*(.*)$')[1:2]
  if len(l:parsed) != 2
    return ["", ""]
  endif
  return l:parsed
endfunction

function! s:get_cmd_obj_and_args_for_complete(arglead, cmdline)
  let l:cmdmenu = get(g:, "cmdmenu", [])
  let [l:command, l:args] = s:parse_cmdline(a:cmdline)
  let l:command = s:prefix_single_match(l:command)(s:menu_cmds(l:cmdmenu))
  let l:cmd_path = split(l:args)
  if !empty(a:arglead)
    let l:cmd_path = l:cmd_path[:-2]
  endif
  let l:cmd_path = extend([l:command], l:cmd_path)
  return s:cmd_obj_by_path(l:cmdmenu, l:cmd_path)
endfunction

function! s:complete_cmd(arglead, cmdline, curpos)
  let [l:cmd_obj, l:cmd_args] = s:get_cmd_obj_and_args_for_complete(a:arglead, a:cmdline)
  " TODO
  "call s:open_completion_window()
  " 1. disable wildmenu storing user setting
  " 2. autocmd: close window & wipe buffer on <c-c>, <esc>, <cr>, <space>
  " (completion done); restore user wildmenu setting (useful for custom
  " completions); highlight on completion selection
  " invoke custom completion function only if there is no possibility to go
  " deeper into submenus, otherwise there is ambiguity in completions
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

function! s:update_command(cmd)
  let l:cmd_rhs_func_args = [
        \ "'".a:cmd."'",
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

function! cmdmenu#update_commands()
  for cmd in s:menu_cmds(g:cmdmenu)
    call s:update_command(cmd)
  endfor
endfunction

"===============================================================================
function! s:reset_state()
  let s:cmd_obj = {}
  let s:cmd_args = []
  let s:should_open_cmdmenu_win = v:false
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

function! s:set_cmd(cmd_path)
  let [l:cmd_obj, l:cmd_args] = s:cmd_obj_by_path(get(g:, "cmdmenu", []), a:cmd_path)
  let s:cmd_obj = l:cmd_obj
  let s:cmd_args = l:cmd_args
endfunction

function! s:arg_is_being_entered(cmdline)
  return a:cmdline =~# '\v\S$'
endfunction

function! s:make_cmd_path(cmdline, command, args, execute)
  let l:cmd_path = split(a:args)
  if !a:execute && s:arg_is_being_entered(a:cmdline)
    let l:cmd_path = l:cmd_path[:-2]
  endif
  let l:cmd_path = extend([a:command], l:cmd_path)
  return l:cmd_path
endfunction

function! s:update_state(cmdline, execute)
  let [l:command, l:args] = s:parse_cmdline(a:cmdline)
  let l:command = s:single_cmdmenu_command(l:command)
  if empty(l:command)
    call s:reset_state()
  else
    let l:cmd_path = s:make_cmd_path(a:cmdline, l:command, l:args, a:execute)
    call s:set_cmd(l:cmd_path)
  endif
endfunction

function! s:store_user_cmaps()
  if !exists("s:user_global_cmaps")
    let s:user_global_cmaps = nvim_get_keymap("c")
  endif
  if !exists("s:user_buffer_cmaps")
    let s:user_buffer_cmaps = nvim_buf_get_keymap(0, "c")
  endif
endfunction

function! s:restore_user_cmaps()
  if exists("s:user_global_cmaps")
    for keymap in s:user_global_cmaps
      let l:opts = {}
      for opt in ['nowait', 'silent', 'expr', 'unique', 'noremap']
        if has_key(keymap, opt)
          let l:opts[opt] = v:true
        endif
      endfor
      call nvim_set_keymap("c", keymap["lhs"], keymap["rhs"], l:opts)
    endfor
    unlet s:user_global_cmaps
  endif
endfunction

function! s:cmap_menu()
endfunction

function! s:cunmap_menu()
endfunction

function! s:update_cmaps()
  call s:store_user_cmaps()
  call s:cmap_menu()
endfunction

function! s:restore_cmaps()
  call s:cunmap_menu()
  call s:restore_user_cmaps()
endfunction

function! s:modify_user_settings()
  " avoid storing modified state
  if !exists("s:user_wildmenu")
    let s:user_wildmenu = &wildmenu
  endif
  set nowildmenu
endfunction

function! s:restore_user_settings()
  if exists("s:user_wildmenu")
    let &wildmenu = s:user_wildmenu
    unlet s:user_wildmenu
  endif
endfunction

function! s:open_win()
endfunction

function! s:open_cmdmenu_help_window()
  if get(s:, "should_open_cmdmenu_win", v:false)
    call s:modify_user_settings()
    call s:open_win()
  endif
endfunction

function! s:close_win()
endfunction

function! s:close_cmdmenu_help_window()
  call s:restore_user_settings()
  call s:close_win()
endfunction

function! s:on_enter()
  call s:reset_state()
endfunction

function! s:on_change()
  call s:close_cmdmenu_help_window()
  call s:restore_user_cmaps()
  call s:update_state(getcmdline(), v:false)
  call s:update_cmaps()
  call s:open_cmdmenu_help_window()
endfunction

function! s:on_leave()
  call s:restore_user_cmaps()
  call s:close_cmdmenu_help_window()
  if v:event["abort"]
    call s:reset_state()
  else
    call s:update_state(getcmdline(), v:true)
  endif
endfunction

augroup cmdmenu_monitoring
  autocmd!
  "autocmd CmdlineEnter : call <sid>on_enter()
  "autocmd CmdlineChanged : call <sid>on_change()
  "autocmd CmdlineLeave : call <sid>on_leave()
augroup end
