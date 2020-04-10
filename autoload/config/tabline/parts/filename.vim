let s:eval_adder = config#statusline#parts#filename#custom#handlers([])
function! config#tabline#parts#filename#add_handler(handler)
  return function(s:eval_adder.adder)(a:handler)
endfunction

function! config#tabline#parts#filename#funcs()
  return [
      \ s:eval_adder.evaluator,
      \ "config#statusline#parts#filename#empty",
      \ "config#statusline#parts#filename#simple",
      \]
endfunction
