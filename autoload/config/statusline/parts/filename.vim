let config#statusline#parts#filename# = {}

function! s:filename_simple(bufname)
  return g:path#.filename(a:bufname)
endfunction

function! s:filename_empty(bufname)
  if empty(g:path#.filename(a:bufname))
    return "[No Name]"
  endif
  return v:null
endfunction

function! s:filename_shorten_rel_path(bufname)
  let l:base_rel_dir = g:func#.compose(g:path#.full, g:path#.relative(getcwd()), g:path#.basedir)
        \(a:bufname)
  let l:filename = g:path#.filename(a:bufname)
  if l:base_rel_dir ==# "."
    return l:filename
  else
    return g:path#.join(pathshorten(l:base_rel_dir), l:filename)
  endif
endfunction

function! s:ft_help_filename(bufname)
  if getbufvar(a:bufname, "&filetype") ==# "help"
    return s:filename_simple(a:bufname)
  endif
  return v:null
endfunction

function! config#statusline#parts#filename#.add_handler(funcref)
  let s:filename_special_cases = g:list#.unique_append(s:filename_special_cases, a:funcref)
endfunction
let s:filename_special_cases = [
      \]

function! s:filename_special_cases(bufname)
  return g:func#.until_result(s:filename_special_cases)(a:bufname)
endfunction

call config#statusline#parts#filename#.add_handler(funcref("s:ft_help_filename"))

let config#statusline#parts#filename#.funcs = [
      \ funcref("s:filename_special_cases"),
      \ funcref("s:filename_empty"),
      \ funcref("s:filename_shorten_rel_path"),
      \]
