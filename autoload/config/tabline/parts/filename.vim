let config#tabline#parts#filename# = {}

let s:eval_adder = config#statusline#parts#filename#helper#.evaluator_and_adder([])
let config#tabline#parts#filename#.add_handler = function(s:eval_adder.adder, [], s:eval_adder)

function! config#tabline#parts#filename#.funcs()
  return [
      \ g:config#statusline#parts#filename#.empty,
      \ s:eval_adder.evaluator,
      \ g:config#statusline#parts#filename#.simple,
      \]
endfunction
