let ide#lsp#plugins = [
      \ "nvim-lsp",
      \ "asyncomplete.vim",
      \ "asyncomplete-omni.vim",
      \]

function! ide#lsp#hover()
  lua vim.lsp.buf.hover()
endfunction

function! ide#lsp#definition()
  lua vim.lsp.buf.definition()
endfunction

function! ide#lsp#signature_help()
  lua vim.lsp.buf.signature_help()
endfunction

function! ide#lsp#references()
  lua vim.lsp.buf.references()
endfunction

function! ide#lsp#server_status()
  lua print(vim.lsp.buf.server_ready())
endfunction
