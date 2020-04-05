let config#statusline#parts#filename#custom# = {}

let s:empty_evaluator = { bufname -> v:null }
function! config#statusline#parts#filename#custom#.handlers(filename_funcs)
  let l:filename_funcs = a:filename_funcs
  if empty(l:filename_funcs)
    let Evaluator = s:empty_evaluator
  else
    let Evaluator = g:func#.until_result(l:filename_funcs)
  endif
  let l:eval_adder = {}
  let l:eval_adder.evaluator = Evaluator
  function! l:eval_adder.adder(funcref) closure dict
    let l:filename_funcs = g:list#.unique_append(l:filename_funcs, a:funcref)
    let self.evaluator = g:func#.until_result(l:filename_funcs)
  endfunction
  return l:eval_adder
endfunction
