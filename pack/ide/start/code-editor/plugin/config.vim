if exists("g:loaded_ide_code_editor")
  finish
endif
let g:loaded_ide_code_editor = v:true

let g:sneak#label = v:true

let g:pear_tree_ft_disabled = [
      \ "vim",
      \]
let g:pear_tree_repeatable_expand = v:false
let g:pear_tree_smart_openers = v:true
let g:pear_tree_smart_closers = v:true
let g:pear_tree_smart_backspace = v:true

call ext#plugins#load(ide#code_editor#plugins)
