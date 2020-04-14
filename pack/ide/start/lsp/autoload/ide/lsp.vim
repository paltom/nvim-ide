let ide#lsp#plugins = [
      \ "nvim-lsp",
      \ "asyncomplete.vim",
      \ "asyncomplete-omni.vim",
      \ "rainbow_parentheses.vim",
      \ "vista.vim",
      \]

function! ide#lsp#hover()
  call winrestview(b:winview)
  lua vim.lsp.buf.hover()
endfunction

function! ide#lsp#definition()
  call winrestview(b:winview)
  lua vim.lsp.buf.definition()
endfunction

function! ide#lsp#signature_help()
  call winrestview(b:winview)
  lua vim.lsp.buf.signature_help()
endfunction

function! ide#lsp#references()
  call winrestview(b:winview)
  lua vim.lsp.buf.references()
  copen
endfunction

function! ide#lsp#server_status()
  lua print(vim.lsp.buf.server_ready())
endfunction

function! ide#lsp#outline_toggle()
  silent execute "Vista!!"
endfunction

function! ide#lsp#outline_open()
  silent execute "Vista"
endfunction

function! ide#lsp#outline_close()
  silent execute "Vista!"
endfunction
