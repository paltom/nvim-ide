let config#statusline#parts# = {}

let config#statusline#parts#.sep = " "

function! config#statusline#parts#.cwd()
  return "%{pathshorten(g:path#.full(getcwd()))}:"
endfunction

function! config#statusline#parts#.flags(winnr)
  let l:bufnr = winbufnr(win_getid(a:winnr))
  let l:modifiable = getbufvar(l:bufnr, "&modifiable")
  let l:readonly = getbufvar(l:bufnr, "&readonly")
  if l:modifiable && !l:readonly
    let l:modified = getbufvar(l:bufnr, "&modified")
    if l:modified
      return " \u274b"
    else
      return "  "
    endif
  else
    return "\U1f512"
  endif
endfunction

function! config#statusline#parts#.filename(winnr)
  " fixes bug when using helpclose
  if a:winnr <= winnr("$")
    call g:config#statusline#.update()
  endif
  " store active window's cwd
  let l:cwd = getcwd()
  " store cwd's type
  if haslocaldir()
    let l:cwd_type = "l"
  elseif haslocaldir(-1)
    let l:cwd_type = "t"
  else
    let l:cwd_type = ""
  endif
  " set local working directory to the same directory for which statusline is
  " being updated
  " fnamemodify works in context of current working directory
  if a:winnr <= winnr("$")
    " window may have been closed
    silent execute "lcd ".getcwd(a:winnr)
  endif
  let l:filename = g:func#call#.until_result(g:config#statusline#parts#filename#.funcs)
        \(g:func#.compose("win_getid", "winbufnr", "bufname")(a:winnr))
  " restore active window's cwd
  silent execute l:cwd_type."cd ".l:cwd
  return l:filename
endfunction
