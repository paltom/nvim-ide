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

function! util#single_matching_prefix(prefix)
  function! s:single_matching_prefix(prefix, names)
    let l:all_names_matching_prefix = func#filter(
          \ { _, n -> n =~# '\v^'.a:prefix },
          \)
          \(a:names)
    if !empty(l:all_names_matching_prefix)
      if len(l:all_names_matching_prefix) == 1
        return l:all_names_matching_prefix[0]
      endif
      let l:exact_match = func#filter(
            \ { _, m -> m ==# a:prefix },
            \)
            \(l:all_names_matching_prefix)
      if !empty(l:exact_match)
        return
      endif
    endif
    return ""
  endfunction
  return function("s:single_matching_prefix", [a:prefix])
endfunction
