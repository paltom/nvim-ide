if exists("g:loaded_menu_builder")
  finish
endif
let g:loaded_menu_builder = v:true

if !exists("g:menus")
  let g:menus = {}
endif

augroup menu_create_commands
  autocmd!
  autocmd VimEnter * call menu_builder#update_menu_commands()
augroup end
