function! util#sid(script_path)
  let l:scriptnames = func#compose([
        \ func#map({ _, name -> split(name, ": ") }),
        \ func#map({ _, entry -> [str2nr(trim(entry[0])), trim(entry[1])] }),
        \])
        \(split(execute("scriptnames"), "\n"))
  let l:match = func#filter({ _, entry -> entry[1] ==# a:script_path })
        \(l:scriptnames)
  if len(l:match) != 1
    return 0
  else
    return l:match[0][0]
  endif
endfunction
