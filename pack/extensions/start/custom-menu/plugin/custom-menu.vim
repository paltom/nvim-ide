" Test completing command tree
" Test a b
" Test a c
" Test d
function! TestCommCompl(arg_lead, cmd_line, cursor_pos)
  echomsg "Arg: ".a:arg_lead
  echomsg "Cmd: ".a:cmd_line
  echomsg "Pos: ".a:cursor_pos
  let l:candidates = ["a", "d"]
  return join(l:candidates, "\n")
endfunction

command! -nargs=+ -complete=custom,TestCommCompl Test echomsg "test"

augroup cmd_test
  autocmd!
  autocmd CmdlineEnter * let s:wildmenu = &wildmenu
  autocmd CmdlineChanged * if getcmdline() =~# '\v^Test '|set nowildmenu|endif
  autocmd CmdlineLeave * let &wildmenu = s:wildmenu
augroup end
