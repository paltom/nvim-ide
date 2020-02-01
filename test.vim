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
