let s:command_name_pattern = '\v^(\U)*\zs\u\a+\ze'
function! s:cmdline_command_name(cmdline)
  return matchstr(a:cmdline, s:command_name_pattern)
endfunction

let s:command_args_pattern = '\v^(\U)*\u\a+!?\s+\zs.*\ze$'
function! s:cmdline_command_args(cmdline)
  let l:args_str = matchstr(a:cmdline, s:command_args_pattern)
  return split(l:args_str, '\v\ +')
endfunction

function! s:get_cmdline_tokens()
  return s:cmdline_tokens
endfunction

function! s:reset_cmdline_tokens()
  let s:cmdline_tokens = ["", []]
endfunction

let s:cmdline_tokens = s:reset_cmdline_tokens()

function! s:cmdline_parse(cmdline)
  let s:cmdline_tokens = [
        \ s:cmdline_command_name(a:cmdline),
        \ s:cmdline_command_args(a:cmdline),
        \]
endfunction

augroup cmdmenu_monitor_cmdline
  autocmd!
  autocmd CmdlineChanged : call <sid>cmdline_parse(getcmdline())
  autocmd CmdlineLeave : call <sid>reset_cmdline_tokens()
augroup end
