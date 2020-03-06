function! s:find_menu_by_command(cmds, cmd_to_find)
  return filter(copy(a:cmds), { _, cmd_obj -> cmd_obj["cmd"] == a:cmd_to_find})
endfunction

function! custom_menu#get_menu_by_path(command, path)
  function! s:get_cmd_by_path(menu, path)
    let l:next_cmd = get(a:path, 0, "")
    let l:cmd_obj = s:find_menu_by_command(a:menu, l:next_cmd)
    if empty(l:cmd_obj)
      return {}
    endif
    let l:cmd_obj = l:cmd_obj[0]
    let l:next_path = a:path[1:]
    if empty(l:next_path)
      return l:cmd_obj
    endif
    if !has_key(l:cmd_obj, "menu")
      return {}
    endif
    return s:get_cmd_by_path(l:cmd_obj["menu"], l:next_path)
  endfunction
  let l:menu = g:custom_menu[a:command]
  return s:get_cmd_by_path(l:menu, a:path)
endfunction

function! s:menu_completions(cmd_lead, cmdline, cursor_pos)
  function! s:map_cmd(cmd_list)
    return map(copy(a:cmd_list), { _, cmd_obj -> cmd_obj["cmd"]})
  endfunction
  let l:cmdline_splitted = split(a:cmdline)
  let l:command = l:cmdline_splitted[0]
  let l:path = l:cmdline_splitted[1:]
  if !empty(a:cmd_lead)
    let l:path = l:path[:-2]
  endif
  if empty(l:path)
    let l:candidates = s:map_cmd(g:custom_menu[l:command])
  else
    let l:cmd_obj = custom_menu#get_menu_by_path(l:command, l:path)
    let l:candidates = s:map_cmd(get(l:cmd_obj, "menu", []))
  endif
  return join(l:candidates, "\n")
endfunction

function! s:execute_action(action)
  if type(a:action) == v:t_string
    execute(a:action)
  elseif type(a:action) == v:t_func
    call a:action()
  else
    echohl WarningMsg
    echomsg "Unknown action type: ".string(a:action)
    echohl None
  endif
endfunction

function! s:menu_action(command, menu_path)
  let l:cmd_obj = custom_menu#get_menu_by_path(a:command, a:menu_path)
  if empty(l:cmd_obj)
    let Action = "echohl WarningMsg|".
          \ "echomsg \"Cannot find unambiguous menu command: '".
          \ join(a:menu_path, " ")."' in '".a:command."' menu\"|".
          \ "echohl None"
  else
    let l:missing_action_msg = "echohl WarningMsg|".
          \ "echomsg 'Missing action for ''".join(a:menu_path, " ").
          \ "'' command in ''".a:command."'' menu'|".
          \ "echohl None"
    let Action = get(l:cmd_obj, "action", l:missing_action_msg)
  endif
  call s:execute_action(Action)
endfunction

function! custom_menu#update_commands()
  for cmd in keys(g:custom_menu)
    execute "command! -nargs=+ -complete=custom,s:menu_completions ".
          \ cmd." call s:menu_action('".cmd."', [<f-args>])"
  endfor
endfunction
