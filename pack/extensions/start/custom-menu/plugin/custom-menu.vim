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

function! s:walk_menu(current_menu, path_to_walk, path_walked)
  echomsg string(a:current_menu)
  echomsg string(a:path_to_walk)
  echomsg string(a:path_walked)
  if len(a:path_to_walk) == 0
    return [a:current_menu, a:path_walked]
  endif
  let l:current_path_elem = a:path_to_walk[0]
  " Filter menu items in current menu that starts with first path element
  let l:submenus = filter(copy(a:current_menu), 'v:val["cmd"] =~# ''\v^'.l:current_path_elem."'")
  if len(l:submenus) == 0
    " If nothing matches, there are no possibilities to go further, path is
    " invalid, we got so far
    return [[], a:path_walked]
  endif
  if len(l:submenus) > 1
    " If element matches exactly and there are more elements in path, go next
    " to matching element
    let l:exact_match = filter(l:submenus, 'v:val["cmd"] ==# "'.l:current_path_elem.'"')
    if len(l:exact_match) == 1 &&
          \ len(a:path_to_walk[1:]) > 0
      let l:submenus = l:exact_match
    else
      " If there are no more elements in the path, we stop here returning
      " possible further steps
      return [a:current_menu, a:path_walked]
    endif
  endif
  " There is exactly one match here
  let l:submenu = l:submenus[0]
  if !has_key(l:submenu, "menu")
    " There is no possibility to go further
    return [l:submenus, a:path_walked]
  endif
  let l:path_walked = add(a:path_walked, l:submenu["cmd"])
  return s:walk_menu(l:submenu["menu"], a:path_to_walk[1:], l:path_walked)
endfunction

function! s:menu_completions(menu_cmd_lead, cmdline, cursor_pos)
  let l:menu_path = split(a:cmdline)
  if empty(a:menu_cmd_lead)
    " Completion is triggered without any leading pattern, path ends with all
    " candidates
    let l:menu_path = add(l:menu_path, '.*')
  endif
  " Which command is used?
  let l:menu_top_cmd = l:menu_path[0]
  let l:menu_top = copy(g:custom_menu[l:menu_top_cmd])
  let l:submenu_path = l:menu_path[1:]
  " Walk through menu while path is unequivocal
  let [l:submenus, l:path_walked] = s:walk_menu(l:menu_top, l:submenu_path, [])
  " Return only arguments that are given explicitly in path
  echomsg string(l:submenus)
  echomsg string(l:path_walked)
  let l:entered_explicitly = empty(a:menu_cmd_lead) ? l:menu_path[1:-2] : l:menu_path[1:]
  echomsg string(l:entered_explicitly)
  if len(l:entered_explicitly) > len(l:path_walked) && empty(a:menu_cmd_lead)
    " If there are more arguments given explicitly than we walked and we ask
    " for more levels, it means we reached menu item without submenus, no
    " candidates should be returned
    echomsg "No candidates"
    return ""
  endif
  let l:candidates = map(copy(l:submenus), 'v:val["cmd"]')
  return join(l:candidates, "\n")
endfunction

command! -nargs=+ -complete=custom,s:menu_completions Test echomsg "test"
