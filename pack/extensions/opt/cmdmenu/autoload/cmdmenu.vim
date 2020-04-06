if !exists("g:cmdmenu")
  let g:cmdmenu = []
endif

function! s:key_filter(key)
  return list#filter({_, co -> has_key(co, a:key)})
endfunction

function! s:menu_cmds(menu)
  const l:key = "cmd"
  return func#compose(
        \ s:key_filter(l:key),
        \ list#map({_,co -> co[l:key]})
        \)
        \(a:menu)
endfunction

function! s:menu_cmd_obj(menu, cmd)
  const l:key = "cmd"
  const l:cmd_objs = func#compose(
        \ s:key_filter(l:key),
        \ list#filter({_, co -> co[l:key] ==# a:cmd}),
        \)
        \(a:menu)
  return get(l:cmd_objs, 0, {})
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

function! cmdmenu#update_commands()
  for cmd in s:menu_cmds(g:cmdmenu)
    call s:update_command(cmd)
  endfor
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

function! s:execute_cmd(cmd, flag, args, mods) range abort
  let l:cmd_menu_path = extend([a:cmd], a:args)
  let [l:cmd_obj, l:cmd_args] = s:cmd_obj_by_path(g:cmdmenu, l:cmd_menu_path)
  if !has_key(l:cmd_obj, "action")
    echohl WarningMsg
    echomsg "No action for this command"
    echohl None
    return
  endif
  execute a:firstline.",".a:lastline."call l:cmd_obj['action'](l:cmd_args, a:flag, a:mods)"
endfunction

function! s:complete_cmd(arglead, cmdline, curpos)
  let [l:command, l:args] = s:parse_cmdline(a:cmdline) " XXX
  let l:command = s:prefix_single_match(l:command)(s:menu_cmds(g:cmdmenu))
  let l:cmd_menu_path = split(l:args)
  if !empty(a:arglead)
    let l:cmd_menu_path = l:cmd_menu_path[:-2]
  endif
  let [l:cmd_obj, l:cmd_args] = s:cmd_obj_by_path(g:cmdmenu, l:cmd_menu_path)
  " invoke custom completion function only if there is no possibility to go
  " deeper into submenus, otherwise there is unambiguity in completions
  " provider
  if !has_key(l:cmd_obj, "menu") && has_key(l:cmd_obj, "complete")
    let l:completion_candidates = l:cmd_obj["complete"](a:arglead, l:cmd_args)
  else
    let l:submenu = get(l:cmd_obj, "menu", [])
    let l:completion_candidates = s:menu_cmds(l:submenu)
  endif
  return join(l:completion_candidates, "\n")
endfunction
