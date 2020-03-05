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
      \       "action": "echo 'Level 2 action (submenu available)",
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

function! s:walk_menu(current_menu, path_to_walk)
  if empty(a:path_to_walk)
    return a:current_menu
  endif
  " Filter menu items in current menu that match first path element
  let l:current_path_elem = a:path_to_walk[0]
  let l:next_items = filter(copy(a:current_menu), 'v:val["cmd"] ==# '''.l:current_path_elem."'")
  if empty(l:next_items)
    return []
  endif
  " There should be exactly one match here
  let l:next_item = l:next_items[0]
  if !has_key(l:next_item, "menu")
    return []
  endif
  return s:walk_menu(l:next_item["menu"], a:path_to_walk[1:])
endfunction

function! s:menu_completions(menu_cmd_lead, cmdline, cursor_pos)
  let l:cmdline_splitted = split(a:cmdline)
  let l:cmd = l:cmdline_splitted[0]
  let l:menu_path = l:cmdline_splitted[1:]
  if !empty(a:menu_cmd_lead)
    let l:menu_path = l:menu_path[:-2]
  endif
  let l:menu_top = copy(g:custom_menu[l:cmd])
  let l:submenu = s:walk_menu(l:menu_top, l:menu_path)
  let l:candidates = map(copy(l:submenu), 'v:val["cmd"]')
  return join(l:candidates, "\n")
endfunction

function! s:menu_action(command, menu_path)
  let l:menu = copy(g:custom_menu[a:command])
  echomsg string(l:menu)
  echomsg "not implemented yet"
endfunction

command! -nargs=+ -complete=custom,s:menu_completions Test call s:menu_action("Test", [<f-args>])

" autocmd VimEnter * call custom_menu#update_commands
" if user wants to add command, he must call custom_menu#add_command or modify
" g:custom_menu variable directly and invoke custom_menu#update_commands
" afterwards
