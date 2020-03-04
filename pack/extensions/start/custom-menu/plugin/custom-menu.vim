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

function! s:walk_menu(current_menu, menu_path)
  echo a:current_menu
  echo a:menu_path
  if len(a:menu_path) == 0
    return a:current_menu
  endif
  let l:current_path_elem = a:menu_path[0]
  let l:submenus = filter(copy(a:current_menu), 'v:val.cmd =~# ''\v^'.l:current_path_elem."'")
  echo l:submenus
  if len(l:submenus) == 0
    echohl WarningMsg
    echomsg "Cannot find submenu starting with '".l:current_path_elem."'"
    echohl None
    return []
  elseif len(l:submenus) > 1
    return a:current_menu
  else
    let l:submenu = l:submenus[0]
    if !has_key(l:submenu, "menu")
      return l:submenu
    endif
    return s:walk_menu(l:submenus[0].menu, a:menu_path[1:])
  endif
endfunction

function! s:menu_completions(menu_cmd_lead, cmdline, cursor_pos)
  let l:menu_path = split(a:cmdline)
  echomsg "Menu path entered so far: ".join(l:menu_path, ':')
  let l:menu_top_cmd = l:menu_path[0]
  let l:menu_top = copy(eval('g:custom_menu.'.l:menu_top_cmd))
  let l:submenu_path = l:menu_path[1:]
  let l:candidates = map(s:walk_menu(l:menu_top, l:submenu_path), 'v:val.cmd')
  return join(l:candidates, "\n")
endfunction

command! -nargs=+ -complete=custom,s:menu_completions Test echomsg "test"
