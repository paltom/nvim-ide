let config#statusline#parts# = {}

let config#statusline#parts#.sep = " "

function! config#statusline#parts#.cwd()
  return pathshorten(g:path#.full(getcwd())).":"
endfunction

function! config#statusline#parts#.flags()
  if &modifiable && !&readonly
    if &modified
      return "  \u274b"
    else
      return "   "
    endif
  else
    return "\U1f512"
  endif
endfunction

function! config#statusline#parts#.filename()
  return g:func#.until_result(g:config#statusline#parts#filename#.funcs)(bufname())
endfunction
