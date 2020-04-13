if !exists("g:cmd_tree")
  let g:cmd_tree = []
endif

function! s:menu_cmds(menu)
  const l:key = "cmd"
  return func#compose(
        \ list#filter({_, co -> has_key(co, l:key)}),
        \ list#map({_,co -> co[l:key]})
        \)
        \(a:menu)
endfunction

function! s:prefix_single_match(prefix, cmds)
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

function! s:menu_cmd_obj(menu, cmd)
  const l:key = "cmd"
  const l:cmd_objs = func#compose(
        \ list#filter({_, co -> has_key(co, l:key)}),
        \ list#filter({_, co -> co[l:key] ==# a:cmd}),
        \)
        \(a:menu)
  return get(l:cmd_objs, 0, {})
endfunction

function! s:cmd_state_by_path(menu, path)
  if empty(a:path)
    return {"obj": {}, "args": [], "visible": v:true}
  endif
  let l:menu = copy(a:menu)
  let l:path = a:path
  let l:cmd_obj = {}
  let l:visible = v:true
  while !empty(l:path)
    let [l:next_cmd; l:next_path] = l:path
    let l:cmd = s:prefix_single_match(l:next_cmd, s:menu_cmds(l:menu))
    if empty(l:cmd)
      break
    endif
    let l:cmd_obj = s:menu_cmd_obj(l:menu, l:cmd)
    let l:visible = l:visible && (!has_key(l:cmd_obj, "condition") || l:cmd_obj["condition"]())
    let l:menu = get(l:cmd_obj, "menu", [])
    let l:path = l:next_path
  endwhile
  return {"obj": l:cmd_obj, "args": l:path, "visible": l:visible}
endfunction

function! s:execute_cmd(command, flag, args, mods) range abort
  let l:cmd_tree = get(g:, "cmd_tree", [])
  let l:cmd_path = extend([a:command], a:args)
  let l:cmd_state = s:cmd_state_by_path(l:cmd_tree, l:cmd_path)
  if !l:cmd_state["visible"]
    echohl WarningMsg
    echomsg "Action not currently available"
    echohl None
    return
  endif
  let l:cmd_obj = l:cmd_state["obj"]
  if !has_key(l:cmd_obj, "action")
    echohl WarningMsg
    echomsg "No action for this command"
    echohl None
    return
  endif
  let l:cmd_args = l:cmd_state["args"]
  execute a:firstline.",".a:lastline."call l:cmd_obj['action'](l:cmd_args, a:flag, a:mods)"
endfunction

function! s:parse_cmdline(cmdline)
  let l:parsed = matchlist(a:cmdline, '\v^\U*(\u\a*)!?\s*(.*)$')[1:2]
  if len(l:parsed) != 2
    return ["", ""]
  endif
  return l:parsed
endfunction

function! s:get_cmd_state_for_complete(arglead, cmdline)
  let l:cmd_tree = get(g:, "cmd_tree", [])
  let [l:command, l:args] = s:parse_cmdline(a:cmdline)
  let l:command = s:prefix_single_match(l:command, s:menu_cmds(l:cmd_tree))
  let l:cmd_path = split(l:args)
  if !empty(a:arglead)
    let l:cmd_path = l:cmd_path[:-2]
  endif
  let l:cmd_path = extend([l:command], l:cmd_path)
  return s:cmd_state_by_path(l:cmd_tree, l:cmd_path)
endfunction

function! s:complete_cmd(arglead, cmdline, curpos)
  " provide completion at cursor position
  let l:cmdline = a:cmdline[:a:curpos - 1]
  let l:arglead = matchstr(l:cmdline, '\v\w+$')
  let l:state = s:get_cmd_state_for_complete(l:arglead, l:cmdline)
  " invoke custom completion function only if there is no possibility to go
  " deeper into submenus, otherwise there is ambiguity in completions
  " provider
  let l:cmd_obj = l:state["obj"]
  let l:cmd_args = l:state["args"]
  if !l:state["visible"]
    let l:completion_candidates = []
  elseif !has_key(l:cmd_obj, "menu") && has_key(l:cmd_obj, "complete")
    let l:completion_candidates = l:cmd_obj["complete"](l:arglead, l:cmd_args)
  elseif empty(l:cmd_args)
    let l:submenu = get(l:cmd_obj, "menu", [])
    let l:visible_cmds = list#filter(
          \ {_, co -> get(co, "condition", { -> v:true})()},
          \)
          \(l:submenu)
    let l:completion_candidates = sort(s:menu_cmds(l:visible_cmds))
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

function! cmd_tree#update_commands()
  for cmd in s:menu_cmds(g:cmd_tree)
    call s:update_command(cmd)
  endfor
endfunction
