let path#sep = expand("/")

function! path#join(...)
  return func#wrap#list_vararg({ elems -> join(elems, g:path#sep) })(a:000)
endfunction

function! path#full(path)
  return fnamemodify(a:path, ":~")
endfunction

function! path#basedir(path)
  return fnamemodify(a:path, ":h")
endfunction

function! path#relative(basepath)
  function! s:relative(path) closure
    let l:basepath_full = path#full(a:basepath)
    if l:basepath_full[-1] !=# g:path#sep
      let l:basepath_full = l:basepath_full.g:path#sep
    endif
    let l:path_full = path#full(a:path)
    let l:path_relative = matchstr(l:path_full, '\v'.l:basepath_full.'\zs.*$')
    if empty(l:path_relative)
      return l:path_full
    else
      return l:path_relative
    endif
  endfunction
  return funcref("s:relative")
endfunction

function! path#filename(path)
  return fnamemodify(a:path, ":t")
endfunction
