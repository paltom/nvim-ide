if exists("g:loaded_menu_builder")
  finish
endif
let g:loaded_menu_builder = v:true

augroup menu_create_commands
  autocmd!
  autocmd VimEnter * call menu_builder#update_menu_commands()
augroup end
