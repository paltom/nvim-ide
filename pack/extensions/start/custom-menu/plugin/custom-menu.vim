let g:custom_menu = {}
" Requirement: Top-level menu must conform to Vim's user command naming rules
" Keys not conforming to above rules are ignored
" Requirement: Menu item contains following keys:
" - "cmd": name of menu item - must conform to Vim's identifier naming rules
" - "action": code to be executed when invoking associated menu item
"   - code may be String - executed with `execute` command
"   - code may be Funcref - executed directly
"   - "action" key is optional, when missing, menu item must contain "menu"
"   key
" - "menu": sub menu available below current menu item
"   - "menu" value is a list of nested menu items
"   - "menu" key is optional, when missing, manu item must contain "action"
"   key
" - Note that both "action" and "menu" may be specified
let g:custom_menu.Test = [
      \ {
      \   "cmd": "level1action",
      \   "action": "echo 'Level 1 action'",
      \ },
      \ {
      \   "cmd": "level1submenu",
      \   "menu": [
      \     {
      \       "cmd": "level2action",
      \       "action": "echo 'Level 2 action'",
      \     },
      \     {
      \       "cmd": "level2actionwithsubmenu",
      \       "action": "echo 'Level 2 action (submenu available)'",
      \       "menu": [
      \         {
      \           "cmd": "level3action",
      \           "action": "echo 'Level 3 action'",
      \         }
      \       ]
      \     }
      \   ]
      \ }
      \]

if !exists('g:custom_menu')
  let g:custom_menu = {}
endif

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
    echomsg "walk: no next items"
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
  execute(a:action)
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
    let l:action = get(l:submenu, "action", l:missing_action_msg)
  else
    let l:action = "echohl WarningMsg|".
          \ "echomsg 'Cannot find unambiguous menu command: ''".
          \ join(a:menu_path, " ")."'' in ''".a:command."'' command'|".
          \ "echohl None"
  endif
  call s:execute_action(l:action)
endfunction

command! -nargs=+ -complete=custom,s:menu_completions Test call s:menu_action("Test", [<f-args>])

" autocmd VimEnter * call custom_menu#update_commands
" if user wants to add command, he must call custom_menu#add_command or modify
" g:custom_menu variable directly and invoke custom_menu#update_commands
" afterwards
