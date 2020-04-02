let config#statusline# = {}

call g:config#statusline#highlight#.update_colors()
augroup config_statusline_update_colors
  autocmd!
  autocmd VimEnter,ColorScheme * call g:config#statusline#highlight#.update_colors()
augroup end

function! config#statusline#.active(winnr)
  let l:stl = [
        \ g:config#statusline#highlight#.part("STLCWD", g:config#statusline#parts#.cwd()),
        \ g:config#statusline#highlight#.part("STLFlags", g:config#statusline#parts#.flags(a:winnr)),
        \ g:config#statusline#parts#.sep,
        \ "%<".g:config#statusline#parts#.filename(a:winnr),
        \ g:config#statusline#parts#.sep,
        \]
  return join(l:stl, "")
endfunction

function! config#statusline#.inactive(winnr)
  let l:stl = [
        \ g:config#statusline#parts#.cwd(),
        \ g:config#statusline#highlight#.part("STLFlags", g:config#statusline#parts#.flags(a:winnr)),
        \ g:config#statusline#parts#.sep,
        \ "%<".g:config#statusline#parts#.filename(a:winnr),
        \ g:config#statusline#parts#.sep,
        \]
  return join(l:stl, "")
endfunction

function! config#statusline#.update()
  let l:winnr = winnr()
  for n in range(1, winnr("$"))
    if n == l:winnr
      let l:stl_func = "config#statusline#.active"
    else
      let l:stl_func = "config#statusline#.inactive"
    endif
    call setwinvar(n, "&statusline", "%!".l:stl_func."(".n.")")
  endfor
endfunction
