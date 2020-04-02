let path# = {}

let path#.sep = expand("/")

let path#.join = func#.list_vararg({ elems -> join(elems, g:path#.sep) })

function! path#.full(path)
  return fnamemodify(a:path, ":~")
endfunction

function! path#.basedir(path)
  return fnamemodify(a:path, ":h")
endfunction

function! path#.rel_to_cwd(path)
  return fnamemodify(a:path, ":.")
endfunction

function! path#.filename(path)
  return fnamemodify(a:path, ":t")
endfunction
