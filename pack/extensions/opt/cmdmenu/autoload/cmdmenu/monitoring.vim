function! s:parse_cmdline(cmdline)
  let l:parsed = matchlist(a:cmdline, '\v^\U*(\u\a+)!?\s*(.*)$')[1:2]
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
    let l:cmd = s:prefix_single_match(l:next_cmd)(cmdmenu#cmds(l:menu))
    if empty(l:cmd)
      break
    endif
    let l:cmd_obj = s:menu_cmd_obj(l:menu, l:cmd)
    let l:menu = get(l:cmd_obj, "menu", [])
    let l:path = l:next_path
  endwhile
  return [l:cmd_obj, l:path]
endfunction

function! cmdmenu#monitoring#reset()
  let s:state = {
        \ "complete": {
        \   "cmd_obj": {},
        \   "cmd_args": [],
        \ },
        \ "cmd_obj": {},
        \ "cmd_args": [],
        \ "info": {
        \   "win": 0,
        \   "buf": 0,
        \ },
        \}
endfunction

function! s:set_state(cmdline, cmdcurpos)
  let [l:command, l:args] = s:parse_cmdline(a:cmdline)
  let l:command = s:prefix_single_match(l:command)(cmdmenu#cmds(get(g:, "cmdmenu", [])))
  let l:args = split(l:args)
  if a:cmdline =~# '\v\S$'
    let [l:cmd_path, l:last_arg] = [l:args[:-2], l:args[-1:]]
  else
    let [l:cmd_path, l:last_arg] = [l:args, []]
  endif
  let l:cmd_path = extend([l:command], l:cmd_path)
  let [l:complete_cmd_obj, l:complete_cmd_args] = s:cmd_obj_by_path(get(g:, "cmdmenu", []), l:cmd_path)
  let s:state["complete"]["cmd_obj"] = l:complete_cmd_obj
  let s:state["complete"]["cmd_args"] = l:complete_cmd_args
  if !empty(l:last_arg)
    if has_key(l:complete_cmd_obj, "menu")
      let [l:cmd_obj, l:cmd_args] = s:cmd_obj_by_path(l:complete_cmd_obj["menu"], l:last_arg)
    else
      let [l:cmd_obj, l:cmd_args] = [l:complete_cmd_obj, extend(l:complete_cmd_args, l:last_arg)]
    endif
  else
    let [l:cmd_obj, l:cmd_args] = [l:complete_cmd_obj, l:complete_cmd_args]
  endif
  let s:state["cmd_obj"] = l:cmd_obj
  let s:state["cmd_args"] = l:cmd_args
endfunction

function! cmdmenu#monitoring#get_state()
  return deepcopy(s:state)
endfunction

function! cmdmenu#monitoring#start()
  call cmdmenu#monitoring#reset()
  "echomsg "start monitoring cmdline"
endfunction

function! cmdmenu#monitoring#update(cmdline, cmdcurpos)
  call s:set_state(a:cmdline, a:cmdcurpos)
  " update window displaying menu information
  " || if window exists but is not visible
  if !s:state["info"]["win"] && !empty(s:state["cmd_obj"])
    echomsg "show cmdmenu window"
    "echomsg printf("cmdline state: %s", s:state)
    let s:state["info"]["win"] = 1
  endif
endfunction

function! cmdmenu#monitoring#stop()
  " close the window
  "echomsg "stop monitoring"
  " if window exists and is visible, close it, wipe the buffer, reset ONLY
  " info key in state
  if s:state["info"]["win"]
    echomsg "close cmdmenu window"
  endif
endfunction
