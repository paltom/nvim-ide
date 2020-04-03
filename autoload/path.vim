let path# = {}

let path#.sep = expand("/")

let path#.join = func#wrap#.list_vararg({ elems -> join(elems, g:path#.sep) })

function! path#.full(path)
  return fnamemodify(a:path, ":~")
endfunction

function! path#.basedir(path)
  return fnamemodify(a:path, ":h")
endfunction

function! path#.relative(basepath)
  function! s:relative(basepath, path)
    let l:basepath_full = g:path#.full(a:basepath)
    if l:basepath_full[-1] !=# g:path#.sep
      let l:basepath_full = l:basepath_full.g:path#.sep
    endif
    let l:path_full = g:path#.full(a:path)
    let l:path_relative = matchstr(l:path_full, '\v'.l:basepath_full.'\zs.*$')
    if empty(l:path_relative)
      return l:path_full
    else
      return l:path_relative
    endif
  endfunction
  return funcref("s:relative", [a:basepath])
endfunction

function! path#.filename(path)
  return fnamemodify(a:path, ":t")
endfunction
