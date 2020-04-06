let s:guard = "g:loaded_cmdmenu"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

if !exists("g:cmdmenu")
  let g:cmdmenu = []
endif

augroup cmdmenu_monitoring
  autocmd!
  autocmd CmdlineEnter : call cmdmenu#monitoring#start()
  autocmd CmdlineChanged : call cmdmenu#monitoring#update(getcmdline(), getcmdpos())
  autocmd CmdlineLeave : call cmdmenu#monitoring#stop()
augroup end

augroup cmdmenu_update
  autocmd!
  autocmd VimEnter * call cmdmenu#update_commands()
augroup end

command! CmdmenuUpdate call cmdmenu#update_commands()
