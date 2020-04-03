let config#statusline#parts#filename# = {}

function! config#statusline#parts#filename#.simple(bufname)
  return g:path#.filename(a:bufname)
endfunction

function! config#statusline#parts#filename#.empty(bufname)
  if empty(g:path#.filename(a:bufname))
    return "[No Name]"
  endif
  return v:null
endfunction

function! config#statusline#parts#filename#.shorten_rel_path(bufname)
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
    return g:config#statusline#parts#filename#.simple(a:bufname)
  endif
  return v:null
endfunction

let s:filename_special_cases = [
      \]
function! config#statusline#parts#filename#.add_handler(funcref)
  let s:filename_special_cases = g:list#.unique_append(s:filename_special_cases, a:funcref)
endfunction

function! s:filename_special_cases(bufname)
  return g:func#.until_result(s:filename_special_cases)(a:bufname)
endfunction

call config#statusline#parts#filename#.add_handler(funcref("s:ft_help_filename"))

let config#statusline#parts#filename#.funcs = [
      \ config#statusline#parts#filename#.empty,
      \ funcref("s:filename_special_cases"),
      \ config#statusline#parts#filename#.shorten_rel_path,
      \]
