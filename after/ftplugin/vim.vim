setlocal expandtab tabstop=2 softtabstop=2 shiftwidth=2 shiftround
if !exists("b:undo_ftplugin")
  let b:undo_ftplugin = ""
endif
let b:undo_ftplugin .= "|setlocal expandtab< tabstop< softtabstop< shiftwidth< shiftround<"
