function! s:find_menu_by_command(menu, cmd_to_find)
  return filter(copy(a:menu), 'v:val["cmd"] ==# '''.a:cmd_to_find."'")
endfunction

function! s:get_submenu(current_menu, submenu_path)
  if empty(a:submenu_path)
    return a:current_menu
  endif
  " Filter menu items in current menu that match first path element
  let l:current_path_elem = a:submenu_path[0]
  let l:next_items = s:find_menu_by_command(a:current_menu, l:current_path_elem)
  if empty(l:next_items)
    return []
  endif
  " There should be exactly one match here
  let l:next_item = l:next_items[0]
  return s:get_submenu(get(l:next_item, "menu", []), a:submenu_path[1:])
endfunction

function! s:menu_completions(menu_cmd_lead, cmdline, cursor_pos)
  let l:cmdline_splitted = split(a:cmdline)
  let l:cmd = l:cmdline_splitted[0]
  let l:menu_path = l:cmdline_splitted[1:]
  if !empty(a:menu_cmd_lead)
    let l:menu_path = l:menu_path[:-2]
  endif
  let l:menu_top = copy(g:custom_menu[l:cmd])
  let l:submenu = s:get_submenu(l:menu_top, l:menu_path)
  let l:candidates = map(copy(l:submenu), 'v:val["cmd"]')
  return join(l:candidates, "\n")
endfunction

function! s:execute_action(action)
  if type(a:action) == v:t_string
    execute(a:action)
  elseif type(a:action) == v:t_func
    call a:action()
  else
    echohl WarningMsg
    echomsg "Unknown action type: ".string(action)
    echohl None
  endif
endfunction

function! s:menu_action(command, menu_path)
  let l:menu = copy(g:custom_menu[a:command])
  let l:menu_cmd = a:menu_path[-1]
  let l:menu_containing_menu_cmd = s:get_submenu(l:menu, a:menu_path[:-2])
  let l:submenus = s:find_menu_by_command(l:menu_containing_menu_cmd, l:menu_cmd)
  if len(l:submenus) == 1
    let l:submenu = l:submenus[0]
    let l:missing_action_msg = "echohl WarningMsg|".
          \ "echomsg 'Missing action for ''".join(a:menu_path, " ").
          \ "'' in command ''".a:command."'''|".
          \ "echohl None"
    call s:execute_action(get(l:submenu, "action", l:missing_action_msg))
  else
    echohl WarningMsg.
    echomsg "Cannot find unambiguous menu command: '".
          \ join(a:menu_path, " ")."' in '".a:command."' command"
    echohl None
  endif
endfunction

function! custom_menu#update_commands()
  for cmd in keys(g:custom_menu)
    execute "command! -nargs=+ -complete=custom,s:menu_completions ".
          \ cmd." call s:menu_action('".cmd."', [<f-args>])"
  endfor
endfunction
