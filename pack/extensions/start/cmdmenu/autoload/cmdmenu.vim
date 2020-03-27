let s:command_name_pattern = '\v^(\U)*\zs\u\a+\ze'
function! s:cmdline_command_name(cmdline)
  return matchstr(a:cmdline, s:command_name_pattern)
endfunction

let s:command_args_pattern = '\v^(\U)*\u\a+!?\s+\zs.*\ze$'
function! s:cmdline_command_args(cmdline)
  let l:args_str = matchstr(a:cmdline, s:command_args_pattern)
  return split(l:args_str, '\v\ +')
endfunction

function! s:cmdline_parse(cmdline)
  return [s:cmdline_command_name(a:cmdline), s:cmdline_command_args(a:cmdline)]
endfunction
