let s:guard = "g:loaded_ide_lsp"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

inoremap <c-space> <c-x><c-o>

call config#ext_plugins#load(ide#lsp#plugins)

call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
      \ "name": "omni",
      \ "whitelist": ["*"],
      \ "completor": function("asyncomplete#sources#omni#completor"),
      \}))

lua require("nvim_lsp").pyls.setup{}
lua require("nvim_lsp").clojure_lsp.setup{}
augroup ide_lsp_omnifunc
  autocmd!
  let s:omnifunc_filetypes = [
        \ "python",
        \ "clojure",
        \]
  execute "autocmd FileType ".join(s:omnifunc_filetypes, ",").
        \ " setlocal omnifunc=v:lua.vim.lsp.omnifunc"
augroup end
