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
" Requirement: if user wants to add command, he must modify g:custom_menu variable directly
" and invoke custom_menu#update_commands afterwards
if exists('g:loaded_custom_menu')
  finish
endif
let g:loaded_custom_menu = v:true

if !exists('g:custom_menu')
  let g:custom_menu = {}
endif

augroup custom_menu_setup
  autocmd!
  autocmd VimEnter * call custom_menu#update_commands()
augroup end
