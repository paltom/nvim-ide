let pack#internal_tests#plugins = [
      \"vader.vim"
      \]

function! s:verb_exe(cmd, arg)
  return execute(join(["verbose", a:cmd, a:arg], " "))
endfunction

let s:set_path_pattern = '\v^Last set from \zs.*\ze line \d+$'
function! pack#internal_tests#option_set_path(option_name)
  let l:verb_output = s:verb_exe("set", a:option_name."?")
  let l:set_line = trim(split(l:verb_output, "\n")[1])
  let l:set_path = matchstr(l:set_line, s:set_path_pattern)
  return l:set_path
endfunction
