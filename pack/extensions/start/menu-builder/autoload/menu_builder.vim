if !exists("g:menus")
  let g:menus = {}
endif

" =============================================================================
let g:menus["Test"] = []

" =============================================================================
function! menu_builder#update_menu_commands()
  for menu_name in keys(g:menus)
    call menu_builder#update_menu_command(menu_name)
  endfor
endfunction

function! menu_builder#update_menu_command(menu_name)
  let l:command_def = "command! "
  let l:command_def.= "-nargs=+ "
  let l:command_def.= "-complete=custom,s:complete_menu_cmd "
  let l:command_def.= "-range "
  let l:command_def.= "-bang "
  let l:command_def.= "-bar "
  let l:command_def.= a:menu_name." "
  let l:command_def.= "call s:invoke_menu_command("
  let l:command_def.= "<bang>v:false,"
  let l:command_def.= "<range>?[<line1>,<line2>][0:<range>-1]:[],"
  let l:command_def.= "split(<q-args>),"
  let l:command_def.= "<q-mods>,"
  let l:command_def.= ")"
  echomsg "Executing ".l:command_def
  execute l:command_def
endfunction

function! s:invoke_menu_command(
      \ flag,
      \ range,
      \ args,
      \ mods,
      \)
  echomsg "Command executed with:"
  echomsg "flag: ".a:flag
  echomsg "range: ".string(a:range)
  echomsg "args: ".string(a:args)
  echomsg "mods: ".a:mods
endfunction

function! s:complete_menu_cmd(
      \ cmd_being_entered,
      \ cmdline,
      \ cursorpos,
      \)
  " possible items in current menu node
  " current menu mode determined by menu path entered so far, not taking
  " item_being_entered into account
  " menu path entered so far counts from first item after whitespace following
  " command name until last whitespace preceding item_being_entered (which may
  " be empty)
  let l:cmds_in_menu = []
  return join(l:cmds_in_menu, "\n")
endfunction
