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

let s:relative_basedir = g:func#.compose(g:path#.full, g:path#.relative(getcwd()), g:path#.basedir)
function! config#statusline#parts#filename#.shorten_rel_path(bufname)
  let l:base_rel_dir = s:relative_basedir(a:bufname)
  let l:filename = g:path#.filename(a:bufname)
  if l:base_rel_dir ==# "."
    return l:filename
  else
    return g:path#.join(pathshorten(l:base_rel_dir), l:filename)
  endif
endfunction

let s:eval_adder = config#statusline#parts#filename#helper#.evaluator_and_adder([])
let config#statusline#parts#filename#.add_handler = function(s:eval_adder.adder, [], s:eval_adder)

function! config#statusline#parts#filename#.funcs()
  return [
      \ g:config#statusline#parts#filename#.empty,
      \ s:eval_adder.evaluator,
      \ g:config#statusline#parts#filename#.shorten_rel_path,
      \]
endfunction
