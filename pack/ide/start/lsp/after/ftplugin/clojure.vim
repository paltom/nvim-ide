runtime! common/lsp.vim
call config#ext_plugins#load(
      \ "rainbow_parentheses.vim",
      \)
setlocal omnifunc=v:lua.vim.lsp.omnifunc
execute "RainbowParentheses"
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
