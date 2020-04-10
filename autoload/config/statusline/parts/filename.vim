function! config#statusline#parts#filename#simple(bufname)
  return path#filename(a:bufname)
endfunction

function! config#statusline#parts#filename#empty(bufname)
  if empty(path#filename(a:bufname))
    return "[No Name]"
  endif
  return v:null
endfunction

function! config#statusline#parts#filename#shorten_rel_path(bufname)
  " needs to be evaluated each time because of getcwd
  let l:relative_basedir = func#compose(
        \ "path#full",
        \ path#relative(getcwd()),
        \ "path#basedir",
        \)
        \(a:bufname)
  let l:filename = path#filename(a:bufname)
  if l:relative_basedir ==# "."
    return l:filename
  else
    return path#join(pathshorten(l:relative_basedir), l:filename)
  endif
endfunction

let s:eval_adder = config#statusline#parts#filename#custom#handlers([])
function! config#statusline#parts#filename#add_handler(handler)
  return function(s:eval_adder.adder)(a:handler)
endfunction

function! config#statusline#parts#filename#funcs()
  return [
      \ s:eval_adder.evaluator,
      \ "config#statusline#parts#filename#empty",
      \ "config#statusline#parts#filename#shorten_rel_path",
      \]
endfunction
