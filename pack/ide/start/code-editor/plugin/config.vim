let s:guard = "g:loaded_ide_code_edit"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

let g:sneak#label = v:true

let g:pear_tree_ft_disabled = [
      \ "vim",
      \]
let g:pear_tree_repeatable_expand = v:false
let g:pear_tree_smart_openers = v:true
let g:pear_tree_smart_closers = v:true
let g:pear_tree_smart_backspace = v:true

call config#ext_plugins#load(ide#code_editor#plugins)
