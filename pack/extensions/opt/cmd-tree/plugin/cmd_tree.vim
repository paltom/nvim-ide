let s:guard = "g:loaded_cmd_tree"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

if !exists("g:cmd_tree")
  let g:cmd_tree = []
endif

augroup cmd_tree_update
  autocmd!
  autocmd VimEnter * call cmd_tree#update_commands()
augroup end

command! CmdTreeUpdate call cmd_tree#update_commands()
