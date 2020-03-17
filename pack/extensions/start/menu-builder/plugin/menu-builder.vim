command!
      \ -nargs=+
      \ -complete=custom,s:complete_menu_item
      \ -range
      \ -bang
      \ -bar
      \ Test
      \ call s:invoke_menu_command(
      \   <bang>v:false,
      \   <range>?[<line1>, <line2>][0:<range> - 1]:[],
      \   split(<q-args>),
      \   <q-mods>,
      \ )

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

function! s:complete_menu_item(
      \ item_being_entered,
      \ cmdline,
      \ cursorpos,
      \)
  " possible items in current menu node
  " current menu mode determined by menu path entered so far, not taking
  " item_being_entered into account
  " menu path entered so far counts from first item after whitespace following
  " command name until last whitespace preceding item_being_entered (which may
  " be empty)
  let l:items_in_menu = []
  return join(l:items_in_menu, "\n")
endfunction
