runtime! common/lsp.vim
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
lua << EOF
require("nvim_lsp").clojure_lsp.setup{
  initializationOptions = {
    ["project-specs"] = {
      {
        ["project-path"] = "project.clj",
        ["classpath-cmd"] = {"lein", "classpath"}
      }
    }
  }
}
EOF
if !exists("b:undo_ftplugin")
  let b:undo_ftplugin = ""
endif
let b:undo_ftplugin .= "|setlocal omnifunc<"
