function! s:get_sid_script(which_func)
  let l:scriptnames = func#compose([
        \ func#map({ _, name -> split(name, ": ") }),
        \ func#map({ _, entry -> [str2nr(trim(entry[0])), trim(entry[1])] }),
        \])
        \(split(execute("scriptnames"), "\n"))
  return func#filter(a:which_func)(l:scriptnames)
endfunction

function! util#get_full_script_file_path(script_path)
  return fnamemodify(findfile(a:script_path, &runtimepath), ":~")
endfunction

function! util#sid(script_path)
  let l:full_script_path = util#get_full_script_file_path(a:script_path)
  let l:match = s:get_sid_script({ _, entry -> entry[1] ==# l:full_script_path })
  if len(l:match) != 1
    return 0
  else
    return l:match[0][0]
  endif
endfunction

function! util#script_by_sid(snr_nr)
  let l:match = s:get_sid_script({ _, entry -> entry[0] ==# a:snr_nr })
  if len(l:match) != 1
    return ""
  else
    return l:match[0][1]
  endif
endfunction

function! util#single_matching_prefix(prefix)
  function! s:single_matching_prefix(prefix, names)
    if empty(a:prefix)
      return ""
    endif
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
