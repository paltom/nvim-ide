if exists("g:loaded_cmdmenu")
  finish
endif
let g:loaded_cmdmenu = v:true

augroup cmdmenu_update_commands
  autocmd!
  autocmd VimEnter * call cmdmenu#update_commands()
augroup end
