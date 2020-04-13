let s:guard = "g:loaded_ide_lsp"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

call config#ext_plugins#load(ide#lsp#plugins)

lua require("nvim_lsp").pyls.setup{}
augroup ide_lsp_omnifunc
  autocmd!
  let s:omnifunc_filetypes = [
        \ "python",
        \]
  execute "autocmd FileType ".join(s:omnifunc_filetypes, ",").
        \ " setlocal omnifunc=v:lua.vim.lsp.omnifunc"
augroup end
