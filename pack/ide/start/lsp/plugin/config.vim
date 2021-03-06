let s:guard = "g:loaded_ide_lsp"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

inoremap <c-space> <c-x><c-o>
call config#ext_plugins#load(
      \ "asyncomplete.vim",
      \ "asyncomplete-omni.vim",
      \)
call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
      \ "name": "omni",
      \ "whitelist": ["*"],
      \ "completor": function("asyncomplete#sources#omni#completor"),
      \}))

call config#ext_plugins#load(
      \ "nvim-lsp",
      \ "vista.vim",
      \)

let s:lsp_cmd = {"cmd": "Lsp"}
let s:lsp_hover = {"cmd": "hover", "action": {a,f,m -> ide#lsp#hover()}}
let s:lsp_definition = {"cmd": "definition", "action": {a,f,m -> ide#lsp#definition()}}
let s:lsp_signature_help = {"cmd": "signature_help", "action": {a,f,m -> ide#lsp#signature_help()}}
let s:lsp_references = {"cmd": "references", "action": {a,f,m -> ide#lsp#references()}}
let s:lsp_server_status = {"cmd": "server_status", "action": {a,f,m -> ide#lsp#server_status()}}
let s:lsp_outline = {"cmd": "outline", "action": {a,f,m -> ide#lsp#outline_toggle()}}
let s:lsp_outline_open = {"cmd": "open", "action": {a,f,m -> ide#lsp#outline_open()}}
let s:lsp_outline_close = {"cmd": "close", "action": {a,f,m -> ide#lsp#outline_close()}}
let s:lsp_outline["menu"] = [
      \ s:lsp_outline_open,
      \ s:lsp_outline_close,
      \]
let s:lsp_cmd["menu"] = [
      \ s:lsp_hover,
      \ s:lsp_definition,
      \ s:lsp_signature_help,
      \ s:lsp_references,
      \ s:lsp_server_status,
      \ s:lsp_outline,
      \]
let g:cmd_tree = add(get(g:, "cmd_tree", []), s:lsp_cmd)
call cmd_tree#update_commands()

let g:vista_default_executive = "nvim_lsp"
let g:vista#renderer#enable_icon = v:false
let g:vista_sidebar_position = "vertical rightbelow"

" LSPs configurations
lua << EOF
require("nvim_lsp").clojure_lsp.setup{
  init_options = {
    ["project-specs"] = {
      {
        ["project-path"] = "project.clj",
        ["classpath-cmd"] = {"lein", "classpath"}
      }
    }
  }
}
EOF
