call config#ext_plugins#load(
      \ "rainbow_parentheses.vim",
      \ "vim-sexp",
      \ "vim-sexp-mappings-for-regular-people",
      \)
setlocal omnifunc=v:lua.vim.lsp.omnifunc
execute "RainbowParentheses"
let g:sexp_mappings = {
      \ "sexp_swap_list_backward": "",
      \ "sexp_swap_list_forward": "",
      \ "sexp_swap_element_backward": "",
      \ "sexp_swap_element_forward": "",
      \}
if !exists("b:undo_ftplugin")
  let b:undo_ftplugin = ""
endif
let b:undo_ftplugin .= "|setlocal omnifunc<"
