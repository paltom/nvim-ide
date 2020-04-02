let config#statusline#parts#filename# = {}

function! s:filename_simple(bufname)
  call g:func#call#.set_result(g:path#.filename(a:bufname))
endfunction

function! s:filename_empty(bufname)
  if empty(g:path#.filename(a:bufname))
    call g:func#call#.set_result("[No Name]")
  endif
endfunction

function! s:filename_shorten_rel_path(bufname)
  let l:base_rel_dir = g:func#.compose(g:path#.full, g:path#.rel_to_cwd, g:path#.basedir)(a:bufname)
  let l:filename = g:path#.filename(a:bufname)
  if l:base_rel_dir ==# "."
    call g:func#call#.set_result(l:filename)
  else
    call g:func#call#.set_result(g:path#.join(pathshorten(l:base_rel_dir), l:filename))
  endif
endfunction

let config#statusline#parts#filename#.funcs = [
      \ funcref("s:filename_empty"),
      \ funcref("s:filename_shorten_rel_path"),
      \]
